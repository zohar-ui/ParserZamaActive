-- ============================================
-- ACTIVE LEARNING SYSTEM
-- ============================================
-- Purpose: Capture corrections from validation failures
--          to improve AI parser over time
-- Created: January 9, 2026
-- ============================================

-- Learning Examples Table
-- Stores every correction made during validation review
CREATE TABLE IF NOT EXISTS zamm.log_learning_examples (
    example_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Source tracking
    draft_id UUID REFERENCES zamm.parse_drafts(draft_id) ON DELETE SET NULL,
    validation_report_id UUID REFERENCES zamm.validation_reports(report_id) ON DELETE SET NULL,
    
    -- Original context
    original_text TEXT NOT NULL,
    original_json JSONB NOT NULL,
    
    -- Corrected version
    corrected_json JSONB NOT NULL,
    
    -- What was wrong
    error_type VARCHAR(100) NOT NULL, -- 'missing_field', 'wrong_value', 'wrong_structure', 'wrong_exercise_name'
    error_location VARCHAR(200), -- JSON path: 'sessions[0].blocks[2].prescription.target_reps'
    error_description TEXT,
    
    -- Correction metadata
    corrected_by VARCHAR(100), -- 'human', 'ai_assisted', 'automated'
    correction_notes TEXT,
    
    -- Learning value
    learning_priority INTEGER DEFAULT 5, -- 1-10, how important is this example
    is_included_in_training BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    included_in_training_at TIMESTAMPTZ,
    
    -- Metadata
    tags TEXT[], -- ['hebrew', 'metcon', 'complex_tempo', 'edge_case']
    
    CONSTRAINT valid_priority CHECK (learning_priority BETWEEN 1 AND 10)
);

-- Indexes for learning queries
CREATE INDEX idx_learning_error_type ON zamm.log_learning_examples(error_type);
CREATE INDEX idx_learning_priority ON zamm.log_learning_examples(learning_priority DESC);
CREATE INDEX idx_learning_training ON zamm.log_learning_examples(is_included_in_training);
CREATE INDEX idx_learning_tags ON zamm.log_learning_examples USING gin(tags);
CREATE INDEX idx_learning_created ON zamm.log_learning_examples(created_at DESC);

COMMENT ON TABLE zamm.log_learning_examples IS 
'Active learning system: captures every correction made during validation review to improve AI parser';

COMMENT ON COLUMN zamm.log_learning_examples.error_type IS 
'Category of error: missing_field, wrong_value, wrong_structure, wrong_exercise_name, wrong_block_type';

COMMENT ON COLUMN zamm.log_learning_examples.learning_priority IS 
'1-10 priority for including in training data. 10 = critical edge case, 1 = minor typo';

-- ============================================
-- HELPER FUNCTION: Capture Learning Example
-- ============================================
CREATE OR REPLACE FUNCTION zamm.capture_learning_example(
    p_draft_id UUID,
    p_validation_report_id UUID,
    p_original_text TEXT,
    p_original_json JSONB,
    p_corrected_json JSONB,
    p_error_type VARCHAR,
    p_error_location VARCHAR DEFAULT NULL,
    p_error_description TEXT DEFAULT NULL,
    p_corrected_by VARCHAR DEFAULT 'human',
    p_correction_notes TEXT DEFAULT NULL,
    p_learning_priority INTEGER DEFAULT 5,
    p_tags TEXT[] DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_example_id UUID;
BEGIN
    INSERT INTO zamm.log_learning_examples (
        draft_id,
        validation_report_id,
        original_text,
        original_json,
        corrected_json,
        error_type,
        error_location,
        error_description,
        corrected_by,
        correction_notes,
        learning_priority,
        tags
    ) VALUES (
        p_draft_id,
        p_validation_report_id,
        p_original_text,
        p_original_json,
        p_corrected_json,
        p_error_type,
        p_error_location,
        p_error_description,
        p_corrected_by,
        p_correction_notes,
        p_learning_priority,
        p_tags
    ) RETURNING example_id INTO v_example_id;
    
    RETURN v_example_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION zamm.capture_learning_example IS 
'Captures a learning example when human corrects a parsing error. Returns example_id.';

-- ============================================
-- VIEW: High Priority Learning Examples
-- ============================================
CREATE OR REPLACE VIEW zamm.vw_learning_queue AS
SELECT 
    le.example_id,
    le.error_type,
    le.error_location,
    le.error_description,
    le.learning_priority,
    le.tags,
    le.created_at,
    le.is_included_in_training,
    LENGTH(le.original_text) as text_length,
    jsonb_array_length(le.original_json->'sessions') as num_sessions,
    (
        SELECT COUNT(*) 
        FROM jsonb_array_elements(le.original_json->'sessions') s,
             jsonb_array_elements(s->'blocks') b
    ) as num_blocks
FROM zamm.log_learning_examples le
WHERE le.is_included_in_training = false
ORDER BY le.learning_priority DESC, le.created_at DESC;

COMMENT ON VIEW zamm.vw_learning_queue IS 
'High priority learning examples not yet included in training data';

-- ============================================
-- FUNCTION: Export Learning Examples for Training
-- ============================================
CREATE OR REPLACE FUNCTION zamm.export_learning_examples(
    p_min_priority INTEGER DEFAULT 7,
    p_limit INTEGER DEFAULT 100
) RETURNS TABLE (
    example_id UUID,
    original_text TEXT,
    correct_json JSONB,
    error_type VARCHAR,
    tags TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        le.example_id,
        le.original_text,
        le.corrected_json,
        le.error_type,
        le.tags
    FROM zamm.log_learning_examples le
    WHERE 
        le.is_included_in_training = false
        AND le.learning_priority >= p_min_priority
    ORDER BY le.learning_priority DESC, le.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION zamm.export_learning_examples IS 
'Export high-priority learning examples for AI training. Returns text + correct JSON pairs.';

-- ============================================
-- TRIGGER: Auto-tag based on content
-- ============================================
CREATE OR REPLACE FUNCTION zamm.trg_auto_tag_learning_example()
RETURNS TRIGGER AS $$
DECLARE
    v_tags TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Detect Hebrew
    IF NEW.original_text ~ '[\u0590-\u05FF]' THEN
        v_tags := array_append(v_tags, 'hebrew');
    END IF;
    
    -- Detect complex structures
    IF (SELECT COUNT(*) FROM jsonb_array_elements(NEW.original_json->'sessions') s,
                                  jsonb_array_elements(s->'blocks') b) > 6 THEN
        v_tags := array_append(v_tags, 'complex');
    END IF;
    
    -- Detect METCON
    IF NEW.original_json::text ILIKE '%metcon%' OR 
       NEW.original_json::text ILIKE '%amrap%' OR
       NEW.original_json::text ILIKE '%for time%' THEN
        v_tags := array_append(v_tags, 'metcon');
    END IF;
    
    -- Merge with manual tags
    IF NEW.tags IS NOT NULL THEN
        v_tags := v_tags || NEW.tags;
    END IF;
    
    -- Remove duplicates
    NEW.tags := ARRAY(SELECT DISTINCT unnest(v_tags));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_tag_learning_example
    BEFORE INSERT ON zamm.log_learning_examples
    FOR EACH ROW
    EXECUTE FUNCTION zamm.trg_auto_tag_learning_example();

COMMENT ON FUNCTION zamm.trg_auto_tag_learning_example IS 
'Auto-tags learning examples based on content (hebrew, complex, metcon, etc.)';
