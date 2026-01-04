


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "zamm";


ALTER SCHEMA "zamm" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."commit_full_workout"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_workout_id UUID;
    v_sess_rec RECORD;
    v_blk_rec RECORD;
    v_item_rec RECORD;
    v_session_id UUID;
    v_block_id UUID;
BEGIN
    -- 1. Insert Workout Header
    INSERT INTO zamm.workouts (
        import_id, draft_id, ruleset_id, athlete_id, 
        workout_date, status, created_at, approved_at
    )
    VALUES (
        p_import_id, 
        p_draft_id, 
        p_ruleset_id, 
        p_athlete_id, 
        (p_normalized_json->'sessions'->0->'sessionInfo'->>'date')::date, 
        'completed',
        NOW(),
        NOW()
    )
    RETURNING workout_id INTO v_workout_id;

    -- 2. Loop through Sessions
    FOR v_sess_rec IN SELECT * FROM jsonb_to_recordset(p_normalized_json->'sessions') AS x(sessionInfo jsonb, blocks jsonb)
    LOOP
        INSERT INTO zamm.workout_sessions (workout_id, session_title, status, created_at)
        VALUES (
            v_workout_id, 
            v_sess_rec.sessionInfo->>'title', 
            'completed',
            NOW()
        )
        RETURNING session_id INTO v_session_id;

        -- 3. Loop through Blocks inside the Session
        FOR v_blk_rec IN SELECT * FROM jsonb_to_recordset(v_sess_rec.blocks) AS y(block_code text, block_type text, name text, prescription jsonb, performed jsonb)
        LOOP
            INSERT INTO zamm.workout_blocks (
                session_id, 
                prescription, 
                performed, -- שים לב: זה דורש את העמודה שהוספנו בסקריפט הקודם
                block_notes, 
                confidence_score,
                created_at
            )
            VALUES (
                v_session_id, 
                v_blk_rec.prescription, 
                v_blk_rec.performed,
                COALESCE(v_blk_rec.name, v_blk_rec.block_code), 
                0.95,
                NOW()
            )
            RETURNING block_id INTO v_block_id;

            -- 4. Loop through Items (Steps) inside the Block
            -- אנו משתמשים ב-WITH ORDINALITY כדי לשמור על סדר התרגילים
            FOR v_item_rec IN SELECT * FROM jsonb_to_recordset(v_blk_rec.prescription->'steps') WITH ORDINALITY AS z(step_data jsonb, ordinality int)
            LOOP
                INSERT INTO zamm.workout_items (
                    block_id, 
                    item_order, 
                    prescription_data, 
                    performed_data,
                    created_at
                )
                VALUES (
                    v_block_id, 
                    v_item_rec.ordinality, 
                    v_item_rec.step_data,
                    -- שליפת הצעד המבוצע התואם לפי האינדקס (אם קיים)
                    COALESCE(v_blk_rec.performed->'steps'->(v_item_rec.ordinality - 1), '{}'::jsonb),
                    NOW()
                );
            END LOOP;
        END LOOP;
    END LOOP;

    -- אם הכל עבר בשלום, הפונקציה מחזירה את ה-ID החדש
    RETURN v_workout_id;

EXCEPTION WHEN OTHERS THEN
    -- במקרה של שגיאה כלשהי, הפונקציה תבצע ROLLBACK אוטומטי לכל השינויים
    -- ותזרוק את השגיאה חזרה ל-n8n
    RAISE;
END;
$$;


ALTER FUNCTION "zamm"."commit_full_workout"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."commit_full_workout_v2"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_workout_id UUID;
    v_sess_rec RECORD;
    v_blk_rec RECORD;
    v_item_rec RECORD;
    v_session_id UUID;
    v_block_id UUID;
    v_workout_date DATE;
BEGIN
    -- חילוץ התאריך מה-JSON (נמצא בתוך הסשן הראשון)
    v_workout_date := (p_normalized_json->'sessions'->0->'sessionInfo'->>'date')::date;

    -- 1. יצירת רשומת האב (Workout)
    INSERT INTO zamm.workouts (
        import_id, draft_id, ruleset_id, athlete_id, 
        workout_date, status, created_at, approved_at
    )
    VALUES (
        p_import_id, p_draft_id, p_ruleset_id, p_athlete_id, 
        v_workout_date, 'completed', NOW(), NOW()
    )
    RETURNING workout_id INTO v_workout_id;

    -- 2. לולאה על הסשנים (Sessions)
    FOR v_sess_rec IN SELECT * FROM jsonb_to_recordset(p_normalized_json->'sessions') AS x(sessionInfo jsonb, blocks jsonb)
    LOOP
        INSERT INTO zamm.workout_sessions (workout_id, session_title, status, created_at)
        VALUES (
            v_workout_id, 
            COALESCE(v_sess_rec.sessionInfo->>'title', 'Main Session'), 
            'completed',
            NOW()
        )
        RETURNING session_id INTO v_session_id;

        -- 3. לולאה על הבלוקים (Blocks)
        FOR v_blk_rec IN SELECT * FROM jsonb_to_recordset(v_sess_rec.blocks) AS y(block_code text, name text, prescription jsonb, performed jsonb)
        LOOP
            INSERT INTO zamm.workout_blocks (
                session_id, 
                prescription, 
                performed,    -- מוודא שיש לך את העמודה הזו (הוספנו אותה קודם)
                block_notes, 
                confidence_score,
                created_at
            )
            VALUES (
                v_session_id, 
                v_blk_rec.prescription, 
                COALESCE(v_blk_rec.performed, '{}'::jsonb),
                COALESCE(v_blk_rec.name, v_blk_rec.block_code), 
                0.95,
                NOW()
            )
            RETURNING block_id INTO v_block_id;

            -- 4. לולאה על התרגילים (Items)
            -- שימוש ב-WITH ORDINALITY מבטיח שהסדר המקורי נשמר
            FOR v_item_rec IN SELECT * FROM jsonb_to_recordset(v_blk_rec.prescription->'steps') WITH ORDINALITY AS z(step_data jsonb, ordinality int)
            LOOP
                INSERT INTO zamm.workout_items (
                    block_id, 
                    item_order, 
                    prescription_data, 
                    performed_data,
                    created_at
                )
                VALUES (
                    v_block_id, 
                    v_item_rec.ordinality, 
                    v_item_rec.step_data,
                    -- שליפת הצעד המבוצע התואם לפי האינדקס (אם קיים)
                    COALESCE(v_blk_rec.performed->'steps'->(v_item_rec.ordinality - 1), '{}'::jsonb),
                    NOW()
                );
            END LOOP;
        END LOOP;
    END LOOP;

    -- החזרת ה-ID של האימון החדש כאישור להצלחה
    RETURN v_workout_id;

EXCEPTION WHEN OTHERS THEN
    -- במקרה של שגיאה כלשהי, הכל מתבטל אוטומטית (Rollback) והשגיאה עולה למעלה
    RAISE;
END;
$$;


ALTER FUNCTION "zamm"."commit_full_workout_v2"("p_import_id" "uuid", "p_draft_id" "uuid", "p_ruleset_id" "uuid", "p_athlete_id" "uuid", "p_normalized_json" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "zamm"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "zamm"."update_modtime"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "zamm"."update_modtime"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."patch_history" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "run_id" "text",
    "raw_text" "text",
    "parser_code" "text",
    "patches" "jsonb",
    "feedback" "jsonb",
    "score" integer
);


ALTER TABLE "public"."patch_history" OWNER TO "postgres";


ALTER TABLE "public"."patch_history" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."patch_history_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "zamm"."dim_athletes" (
    "athlete_sk" integer NOT NULL,
    "athlete_natural_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "full_name" character varying(100) NOT NULL,
    "email" character varying(255),
    "phone" character varying(50),
    "gender" character varying(20) DEFAULT 'unknown'::character varying,
    "date_of_birth" "date",
    "height_cm" integer,
    "current_weight_kg" numeric(5,2),
    "valid_from" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "valid_to" timestamp with time zone,
    "is_current" boolean DEFAULT true,
    "data_source" character varying(50) DEFAULT 'n8n_agent'::character varying,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "dim_athletes_gender_check" CHECK ((("gender")::"text" = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying, 'unknown'::character varying])::"text"[])))
);


ALTER TABLE "zamm"."dim_athletes" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "zamm"."dim_athletes_athlete_sk_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "zamm"."dim_athletes_athlete_sk_seq" OWNER TO "postgres";


ALTER SEQUENCE "zamm"."dim_athletes_athlete_sk_seq" OWNED BY "zamm"."dim_athletes"."athlete_sk";



CREATE TABLE IF NOT EXISTS "zamm"."draft_edits" (
    "edit_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "editor_id" "uuid",
    "patch" "jsonb" NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."draft_edits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."equipment_aliases" (
    "alias" "text" NOT NULL,
    "equipment_key" "text" NOT NULL,
    "locale" "text" DEFAULT 'en'::"text" NOT NULL
);


ALTER TABLE "zamm"."equipment_aliases" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."equipment_catalog" (
    "equipment_key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "zamm"."equipment_catalog" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."equipment_config_templates" (
    "equipment_key" "text" NOT NULL,
    "template" "jsonb" NOT NULL
);


ALTER TABLE "zamm"."equipment_config_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."imports" (
    "import_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source" "text" NOT NULL,
    "source_ref" "text",
    "athlete_id" "uuid",
    "raw_text" "text" NOT NULL,
    "raw_payload" "jsonb",
    "received_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "checksum_sha256" "text",
    "tags" "text"[] DEFAULT '{}'::"text"[] NOT NULL
);


ALTER TABLE "zamm"."imports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."interval_segments" (
    "segment_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "rep_index" integer NOT NULL,
    "work_time_sec" integer,
    "rest_time_sec" integer,
    "distance_m" integer,
    "pace_text" "text",
    "hr_bpm" integer,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."interval_segments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."item_set_results" (
    "set_result_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "set_index" integer NOT NULL,
    "reps" integer,
    "load_kg" numeric(10,2),
    "rpe" numeric(4,2),
    "rir" numeric(4,2),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."item_set_results" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."parse_drafts" (
    "draft_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "import_id" "uuid" NOT NULL,
    "ruleset_id" "uuid" NOT NULL,
    "parser_version" "text" NOT NULL,
    "stage" "text" NOT NULL,
    "confidence_score" numeric(4,3),
    "parsed_draft" "jsonb" NOT NULL,
    "normalized_draft" "jsonb",
    "flags" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "approved_by" "uuid",
    "rejected_at" timestamp with time zone,
    "rejected_by" "uuid",
    "rejection_reason" "text",
    "stage_snapshots" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "zamm"."parse_drafts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."parser_rulesets" (
    "ruleset_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "version" "text" NOT NULL,
    "is_active" boolean DEFAULT false NOT NULL,
    "units_catalog" "jsonb" NOT NULL,
    "units_metadata" "jsonb" NOT NULL,
    "parser_mapping_rules" "jsonb" NOT NULL,
    "value_unit_schema" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."parser_rulesets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."workout_blocks" (
    "block_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" "uuid" NOT NULL,
    "letter" "text",
    "block_code" "text" NOT NULL,
    "block_type" "text" NOT NULL,
    "name" "text" NOT NULL,
    "structure_model" "text" NOT NULL,
    "presentation_structure" "text" NOT NULL,
    "result_entry_model" "text" NOT NULL,
    "prescription" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "raw_block_text" "text" DEFAULT ''::"text" NOT NULL,
    "confidence_score" numeric(4,3) DEFAULT 1.000 NOT NULL,
    "block_notes" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "performed" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "zamm"."workout_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."workout_items" (
    "item_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "exercise_name" "text" NOT NULL,
    "category" "text",
    "pattern" "text",
    "equipment_primary" "text",
    "equipment_config" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "dose" "jsonb",
    "load" "jsonb",
    "intensity" "jsonb",
    "device" "jsonb",
    "tempo" "text",
    "notes" "text",
    "original_text" "text",
    "item_order" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "equipment_key" "text",
    "prescription_data" "jsonb" DEFAULT '{}'::"jsonb",
    "performed_data" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "zamm"."workout_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."workout_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "workout_id" "uuid" NOT NULL,
    "date" "date",
    "week_number" integer,
    "day_of_week" integer,
    "day_name" "text",
    "phase_name" "text",
    "session_title" "text",
    "session_type" "text" DEFAULT 'training'::"text" NOT NULL,
    "status" "text" DEFAULT 'planned'::"text" NOT NULL,
    "estimated_duration_min" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."workout_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."workouts" (
    "workout_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "import_id" "uuid" NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "ruleset_id" "uuid" NOT NULL,
    "athlete_id" "uuid",
    "workout_date" "date",
    "session_title" "text",
    "session_type" "text" DEFAULT 'training'::"text" NOT NULL,
    "status" "text" DEFAULT 'planned'::"text" NOT NULL,
    "estimated_duration_min" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_by" "uuid"
);


ALTER TABLE "zamm"."workouts" OWNER TO "postgres";


CREATE OR REPLACE VIEW "zamm"."v_analytics_flat_history" AS
 SELECT "w"."workout_date",
    "w"."workout_id",
    "s"."session_title",
    "b"."block_code",
    "b"."name" AS "block_name",
    "i"."item_order",
    COALESCE(("i"."prescription_data" ->> 'exercise_name'::"text"), 'Unknown Exercise'::"text") AS "exercise",
    "r"."reps" AS "reps_performed",
    "r"."load_kg",
    "r"."rpe",
    "r"."rir"
   FROM (((("zamm"."workouts" "w"
     JOIN "zamm"."workout_sessions" "s" ON (("w"."workout_id" = "s"."workout_id")))
     JOIN "zamm"."workout_blocks" "b" ON (("s"."session_id" = "b"."session_id")))
     JOIN "zamm"."workout_items" "i" ON (("b"."block_id" = "i"."block_id")))
     LEFT JOIN "zamm"."item_set_results" "r" ON (("i"."item_id" = "r"."item_id")))
  WHERE ("w"."status" = 'completed'::"text");


ALTER VIEW "zamm"."v_analytics_flat_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."validation_reports" (
    "report_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "draft_id" "uuid" NOT NULL,
    "is_valid" boolean NOT NULL,
    "errors" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "warnings" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "validator_version" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."validation_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "zamm"."workout_block_results" (
    "block_result_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "block_id" "uuid" NOT NULL,
    "did_complete" boolean,
    "total_time_sec" integer,
    "score_time_sec" integer,
    "score_text" "text",
    "distance_m" integer,
    "avg_hr_bpm" integer,
    "calories" integer,
    "athlete_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "zamm"."workout_block_results" OWNER TO "postgres";


ALTER TABLE ONLY "zamm"."dim_athletes" ALTER COLUMN "athlete_sk" SET DEFAULT "nextval"('"zamm"."dim_athletes_athlete_sk_seq"'::"regclass");



ALTER TABLE ONLY "public"."patch_history"
    ADD CONSTRAINT "patch_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "zamm"."workout_block_results"
    ADD CONSTRAINT "block_results_block_id_key" UNIQUE ("block_id");



ALTER TABLE ONLY "zamm"."workout_block_results"
    ADD CONSTRAINT "block_results_pkey" PRIMARY KEY ("block_result_id");



ALTER TABLE ONLY "zamm"."dim_athletes"
    ADD CONSTRAINT "dim_athletes_pkey" PRIMARY KEY ("athlete_sk");



ALTER TABLE ONLY "zamm"."draft_edits"
    ADD CONSTRAINT "draft_edits_pkey" PRIMARY KEY ("edit_id");



ALTER TABLE ONLY "zamm"."equipment_aliases"
    ADD CONSTRAINT "equipment_aliases_pkey" PRIMARY KEY ("alias");



ALTER TABLE ONLY "zamm"."equipment_catalog"
    ADD CONSTRAINT "equipment_catalog_pkey" PRIMARY KEY ("equipment_key");



ALTER TABLE ONLY "zamm"."equipment_config_templates"
    ADD CONSTRAINT "equipment_config_templates_pkey" PRIMARY KEY ("equipment_key");



ALTER TABLE ONLY "zamm"."imports"
    ADD CONSTRAINT "imports_pkey" PRIMARY KEY ("import_id");



ALTER TABLE ONLY "zamm"."interval_segments"
    ADD CONSTRAINT "interval_segments_pkey" PRIMARY KEY ("segment_id");



ALTER TABLE ONLY "zamm"."item_set_results"
    ADD CONSTRAINT "item_set_results_pkey" PRIMARY KEY ("set_result_id");



ALTER TABLE ONLY "zamm"."parse_drafts"
    ADD CONSTRAINT "parse_drafts_pkey" PRIMARY KEY ("draft_id");



ALTER TABLE ONLY "zamm"."parser_rulesets"
    ADD CONSTRAINT "parser_rulesets_name_version_key" UNIQUE ("name", "version");



ALTER TABLE ONLY "zamm"."parser_rulesets"
    ADD CONSTRAINT "parser_rulesets_pkey" PRIMARY KEY ("ruleset_id");



ALTER TABLE ONLY "zamm"."validation_reports"
    ADD CONSTRAINT "validation_reports_pkey" PRIMARY KEY ("report_id");



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_pkey" PRIMARY KEY ("item_id");



ALTER TABLE ONLY "zamm"."workout_sessions"
    ADD CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "zamm"."workouts"
    ADD CONSTRAINT "workouts_pkey" PRIMARY KEY ("workout_id");



CREATE INDEX "idx_block_results_block" ON "zamm"."workout_block_results" USING "btree" ("block_id");



CREATE INDEX "idx_dim_athletes_is_current" ON "zamm"."dim_athletes" USING "btree" ("is_current") WHERE ("is_current" = true);



CREATE INDEX "idx_dim_athletes_name" ON "zamm"."dim_athletes" USING "btree" ("full_name");



CREATE UNIQUE INDEX "idx_dim_athletes_natural_id" ON "zamm"."dim_athletes" USING "btree" ("athlete_natural_id");



CREATE INDEX "idx_draft_edits_created_at" ON "zamm"."draft_edits" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_draft_edits_draft" ON "zamm"."draft_edits" USING "btree" ("draft_id");



CREATE INDEX "idx_imports_athlete" ON "zamm"."imports" USING "btree" ("athlete_id");



CREATE INDEX "idx_imports_received_at" ON "zamm"."imports" USING "btree" ("received_at" DESC);



CREATE INDEX "idx_imports_source" ON "zamm"."imports" USING "btree" ("source");



CREATE INDEX "idx_interval_segments_block" ON "zamm"."interval_segments" USING "btree" ("block_id");



CREATE INDEX "idx_interval_segments_block_rep" ON "zamm"."interval_segments" USING "btree" ("block_id", "rep_index");



CREATE INDEX "idx_item_set_results_block" ON "zamm"."item_set_results" USING "btree" ("block_id");



CREATE INDEX "idx_item_set_results_item" ON "zamm"."item_set_results" USING "btree" ("item_id");



CREATE INDEX "idx_item_set_results_item_set" ON "zamm"."item_set_results" USING "btree" ("item_id", "set_index");



CREATE INDEX "idx_items_performed_gin" ON "zamm"."workout_items" USING "gin" ("performed_data");



CREATE INDEX "idx_items_prescription_gin" ON "zamm"."workout_items" USING "gin" ("prescription_data");



CREATE INDEX "idx_parse_drafts_created_at" ON "zamm"."parse_drafts" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_parse_drafts_import" ON "zamm"."parse_drafts" USING "btree" ("import_id");



CREATE INDEX "idx_parse_drafts_ruleset" ON "zamm"."parse_drafts" USING "btree" ("ruleset_id");



CREATE INDEX "idx_parse_drafts_stage" ON "zamm"."parse_drafts" USING "btree" ("stage");



CREATE INDEX "idx_parser_rulesets_active" ON "zamm"."parser_rulesets" USING "btree" ("is_active");



CREATE INDEX "idx_validation_reports_draft" ON "zamm"."validation_reports" USING "btree" ("draft_id");



CREATE INDEX "idx_validation_reports_valid" ON "zamm"."validation_reports" USING "btree" ("is_valid");



CREATE INDEX "idx_workout_blocks_code" ON "zamm"."workout_blocks" USING "btree" ("block_code");



CREATE INDEX "idx_workout_blocks_result_model" ON "zamm"."workout_blocks" USING "btree" ("result_entry_model");



CREATE INDEX "idx_workout_blocks_session" ON "zamm"."workout_blocks" USING "btree" ("session_id");



CREATE INDEX "idx_workout_items_block" ON "zamm"."workout_items" USING "btree" ("block_id");



CREATE INDEX "idx_workout_items_equipment_key" ON "zamm"."workout_items" USING "btree" ("equipment_key");



CREATE INDEX "idx_workout_items_name" ON "zamm"."workout_items" USING "btree" ("exercise_name");



CREATE INDEX "idx_workout_sessions_workout" ON "zamm"."workout_sessions" USING "btree" ("workout_id");



CREATE INDEX "idx_workouts_athlete_date" ON "zamm"."workouts" USING "btree" ("athlete_id", "workout_date" DESC);



CREATE INDEX "idx_workouts_draft" ON "zamm"."workouts" USING "btree" ("draft_id");



CREATE INDEX "idx_workouts_import" ON "zamm"."workouts" USING "btree" ("import_id");



CREATE OR REPLACE TRIGGER "trg_parse_drafts_updated_at" BEFORE UPDATE ON "zamm"."parse_drafts" FOR EACH ROW EXECUTE FUNCTION "zamm"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_update_athletes_modtime" BEFORE UPDATE ON "zamm"."dim_athletes" FOR EACH ROW EXECUTE FUNCTION "zamm"."update_modtime"();



ALTER TABLE ONLY "zamm"."workout_block_results"
    ADD CONSTRAINT "block_results_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."draft_edits"
    ADD CONSTRAINT "draft_edits_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."parse_drafts"("draft_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."equipment_aliases"
    ADD CONSTRAINT "equipment_aliases_equipment_key_fkey" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."equipment_catalog"("equipment_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."equipment_config_templates"
    ADD CONSTRAINT "equipment_config_templates_equipment_key_fkey" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."equipment_catalog"("equipment_key") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."interval_segments"
    ADD CONSTRAINT "interval_segments_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."item_set_results"
    ADD CONSTRAINT "item_set_results_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."item_set_results"
    ADD CONSTRAINT "item_set_results_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "zamm"."workout_items"("item_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."parse_drafts"
    ADD CONSTRAINT "parse_drafts_import_id_fkey" FOREIGN KEY ("import_id") REFERENCES "zamm"."imports"("import_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."parse_drafts"
    ADD CONSTRAINT "parse_drafts_ruleset_id_fkey" FOREIGN KEY ("ruleset_id") REFERENCES "zamm"."parser_rulesets"("ruleset_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."validation_reports"
    ADD CONSTRAINT "validation_reports_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."parse_drafts"("draft_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_blocks"
    ADD CONSTRAINT "workout_blocks_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "zamm"."workout_sessions"("session_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "zamm"."workout_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workout_items"
    ADD CONSTRAINT "workout_items_equipment_fk" FOREIGN KEY ("equipment_key") REFERENCES "zamm"."equipment_catalog"("equipment_key");



ALTER TABLE ONLY "zamm"."workout_sessions"
    ADD CONSTRAINT "workout_sessions_workout_id_fkey" FOREIGN KEY ("workout_id") REFERENCES "zamm"."workouts"("workout_id") ON DELETE CASCADE;



ALTER TABLE ONLY "zamm"."workouts"
    ADD CONSTRAINT "workouts_draft_id_fkey" FOREIGN KEY ("draft_id") REFERENCES "zamm"."parse_drafts"("draft_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workouts"
    ADD CONSTRAINT "workouts_import_id_fkey" FOREIGN KEY ("import_id") REFERENCES "zamm"."imports"("import_id") ON DELETE RESTRICT;



ALTER TABLE ONLY "zamm"."workouts"
    ADD CONSTRAINT "workouts_ruleset_id_fkey" FOREIGN KEY ("ruleset_id") REFERENCES "zamm"."parser_rulesets"("ruleset_id") ON DELETE RESTRICT;





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."patch_history" TO "anon";
GRANT ALL ON TABLE "public"."patch_history" TO "authenticated";
GRANT ALL ON TABLE "public"."patch_history" TO "service_role";



GRANT ALL ON SEQUENCE "public"."patch_history_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."patch_history_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."patch_history_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";

alter table "zamm"."dim_athletes" drop constraint "dim_athletes_gender_check";

alter table "zamm"."dim_athletes" add constraint "dim_athletes_gender_check" CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying, 'unknown'::character varying])::text[]))) not valid;

alter table "zamm"."dim_athletes" validate constraint "dim_athletes_gender_check";


