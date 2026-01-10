-- ============================================
-- Add Hebrew + Shorthand Equipment Aliases
-- ============================================
-- Purpose: Enable Hebrew workout log parsing
-- Date: 2026-01-10
-- Version: 1.0
-- Author: AI Agent
--
-- Background:
-- 90% of workout logs are in Hebrew, but equipment catalog
-- only has English aliases. This migration adds ~40 Hebrew
-- aliases and additional English shorthand to improve parser
-- recognition rates.
--
-- Tables Modified:
-- - zamm.lib_equipment_aliases (INSERT only)

-- ============================================
-- Hebrew Equipment Aliases
-- ============================================

INSERT INTO zamm.lib_equipment_aliases (alias, equipment_key, locale)
VALUES
  -- Barbell variations
  ('מוט', 'barbell', 'he'),
  ('מטל', 'barbell', 'he'),
  ('מוט משקולות', 'barbell', 'he'),
  
  -- Dumbbell variations
  ('משקולות', 'dumbbell', 'he'),
  ('דמבלים', 'dumbbell', 'he'),
  ('דמבל', 'dumbbell', 'he'),
  ('משקולת', 'dumbbell', 'he'),
  
  -- Kettlebell variations
  ('קטלבל', 'kettlebell', 'he'),
  ('קטלבלים', 'kettlebell', 'he'),
  ('קטל', 'kettlebell', 'he'),
  
  -- Cardio equipment
  ('חתירה', 'rowing_machine', 'he'),
  ('רואינג', 'rowing_machine', 'he'),
  ('משוט', 'rowing_machine', 'he'),
  ('אופניים', 'bike', 'he'),
  ('אופני כביש', 'bike', 'he'),
  ('הליכון', 'treadmill', 'he'),
  ('רצועה', 'treadmill', 'he'),
  ('סקי ארג', 'ski_erg', 'he'),
  
  -- Bands and recovery
  ('גומיה', 'resistance_band', 'he'),
  ('גומיות', 'resistance_band', 'he'),
  ('רצועת התנגדות', 'resistance_band', 'he'),
  ('מיני בנד', 'mini_band', 'he'),
  ('רולר', 'foam_roller', 'he'),
  ('פואם רולר', 'foam_roller', 'he'),
  ('גליל', 'foam_roller', 'he'),
  
  -- Balls
  ('כדור לקרוס', 'lacrosse_ball', 'he'),
  ('כדור קיר', 'wall_ball', 'he'),
  ('כדור משקל', 'medicine_ball', 'he'),
  ('כדור רפואי', 'medicine_ball', 'he'),
  ('סלאם בול', 'slam_ball', 'he'),
  ('כדור להטחה', 'slam_ball', 'he'),
  
  -- Other equipment
  ('חבל', 'jump_rope', 'he'),
  ('חבל קפיצה', 'jump_rope', 'he'),
  ('שק חול', 'sandbag', 'he'),
  ('משקל גוף', 'bodyweight', 'he'),
  ('ללא ציוד', 'none', 'he'),
  ('טבעות', 'rings', 'he'),
  ('בר למתח', 'pull_up_bar', 'he'),
  ('מוט למתח', 'pull_up_bar', 'he'),
  ('מכונת כבלים', 'cable_machine', 'he'),
  ('כבלים', 'cable_machine', 'he'),
  -- Note: smith_machine doesn't exist in catalog yet, commenting out
  -- ('סמית', 'smith_machine', 'he'),
  -- ('מכונת סמית', 'smith_machine', 'he'),
  ('משטח', 'box', 'he'),
  ('קופסה', 'box', 'he'),
  ('סלד', 'sled', 'he'),
  ('מזחלת', 'sled', 'he'),
  ('TRX', 'trx', 'he'),
  ('חבל TRX', 'trx', 'he'),

-- ============================================
-- English Shorthand Aliases
-- ============================================

  -- Common abbreviations
  ('KTB', 'kettlebell', 'en'),
  ('KB', 'kettlebell', 'en'),
  ('DBs', 'dumbbell', 'en'),
  ('DB', 'dumbbell', 'en'),
  ('BB', 'barbell', 'en'),
  ('WB', 'wall_ball', 'en'),
  ('MB', 'medicine_ball', 'en'),
  ('MedBall', 'medicine_ball', 'en'),
  ('SB', 'slam_ball', 'en'),
  ('AB', 'assault_bike', 'en'),
  ('BW', 'bodyweight', 'en'),
  ('TRX', 'trx', 'en'),
  ('PU Bar', 'pull_up_bar', 'en'),
  ('PUB', 'pull_up_bar', 'en'),
  ('Cables', 'cable_machine', 'en'),
  ('JR', 'jump_rope', 'en'),
  ('Box', 'box', 'en')

ON CONFLICT (alias) DO NOTHING;

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify Hebrew aliases:
-- SELECT alias, equipment_key, locale 
-- FROM zamm.lib_equipment_aliases 
-- WHERE locale = 'he' 
-- ORDER BY equipment_key, alias;
