-- ============================================
-- Populate Equipment Catalog
-- ============================================
-- Purpose: Seed lib_equipment_catalog with common gym equipment
-- Date: 2026-01-10
-- Version: 1.0

-- Insert core equipment types
INSERT INTO zamm.lib_equipment_catalog (equipment_key, display_name, category, is_active) 
VALUES
  -- Barbells & Plates
  ('barbell', 'Barbell', 'free_weights', true),
  ('barbell_empty', 'Empty Barbell (20kg)', 'free_weights', true),
  
  -- Dumbbells
  ('dumbbell', 'Dumbbell', 'free_weights', true),
  ('dumbbell_pair', 'Dumbbell Pair', 'free_weights', true),
  
  -- Kettlebells
  ('kettlebell', 'Kettlebell', 'free_weights', true),
  
  -- Cardio Machines
  ('rowing_machine', 'Rowing Machine (C2/Concept2)', 'cardio', true),
  ('assault_bike', 'Assault Bike', 'cardio', true),
  ('bike', 'Stationary Bike', 'cardio', true),
  ('treadmill', 'Treadmill', 'cardio', true),
  ('ski_erg', 'Ski Erg', 'cardio', true),
  
  -- Cable & Machines
  ('cable_machine', 'Cable Machine', 'machines', true),
  ('lat_pulldown', 'Lat Pulldown Machine', 'machines', true),
  ('leg_press', 'Leg Press', 'machines', true),
  
  -- Bodyweight Equipment
  ('pull_up_bar', 'Pull-up Bar', 'bodyweight', true),
  ('dip_station', 'Dip Station', 'bodyweight', true),
  ('rings', 'Gymnastics Rings', 'bodyweight', true),
  ('parallettes', 'Parallettes', 'bodyweight', true),
  
  -- Bands & Resistance
  ('resistance_band', 'Resistance Band', 'bands', true),
  ('mini_band', 'Mini Band', 'bands', true),
  ('heavy_band', 'Heavy Band', 'bands', true),
  
  -- Recovery & Mobility
  ('foam_roller', 'Foam Roller', 'mobility', true),
  ('lacrosse_ball', 'Lacrosse Ball', 'mobility', true),
  ('massage_ball', 'Massage Ball', 'mobility', true),
  ('pvc_pipe', 'PVC Pipe', 'mobility', true),
  
  -- Functional Equipment
  ('slam_ball', 'Slam Ball', 'functional', true),
  ('wall_ball', 'Wall Ball', 'functional', true),
  ('medicine_ball', 'Medicine Ball', 'functional', true),
  ('jump_rope', 'Jump Rope', 'functional', true),
  ('box', 'Plyometric Box', 'functional', true),
  ('sandbag', 'Sandbag', 'functional', true),
  ('sled', 'Sled', 'functional', true),
  
  -- Specialty
  ('landmine', 'Landmine Attachment', 'specialty', true),
  ('trx', 'TRX Suspension Trainer', 'specialty', true),
  ('ab_wheel', 'Ab Wheel', 'specialty', true),
  
  -- None/Bodyweight
  ('bodyweight', 'Bodyweight Only', 'bodyweight', true),
  ('none', 'No Equipment', 'bodyweight', true)

ON CONFLICT (equipment_key) DO NOTHING;

-- Create equipment aliases for common variations
INSERT INTO zamm.lib_equipment_aliases (alias, equipment_key)
VALUES
  -- Barbell variations
  ('bar', 'barbell'),
  ('empty bar', 'barbell_empty'),
  ('BB', 'barbell'),
  
  -- Dumbbell variations
  ('DB', 'dumbbell'),
  ('DBs', 'dumbbell_pair'),
  ('dumbbells', 'dumbbell_pair'),
  
  -- Kettlebell variations
  ('KB', 'kettlebell'),
  ('KBs', 'kettlebell'),
  
  -- Rowing machine
  ('C2', 'rowing_machine'),
  ('C2 Row', 'rowing_machine'),
  ('Concept2', 'rowing_machine'),
  ('erg', 'rowing_machine'),
  ('rower', 'rowing_machine'),
  ('Row', 'rowing_machine'),
  
  -- Bikes
  ('Bike', 'bike'),
  ('AB', 'assault_bike'),
  ('Air Bike', 'assault_bike'),
  
  -- Bands
  ('band', 'resistance_band'),
  ('mini band', 'mini_band'),
  ('minband', 'mini_band'),
  
  -- Bodyweight
  ('BW', 'bodyweight'),
  ('body weight', 'bodyweight'),
  ('no equipment', 'none'),
  
  -- Mobility
  ('FR', 'foam_roller'),
  ('foam roll', 'foam_roller'),
  ('lacrosse', 'lacrosse_ball'),
  ('PVC', 'pvc_pipe'),
  
  -- Other
  ('WB', 'wall_ball'),
  ('medicine ball', 'medicine_ball'),
  ('med ball', 'medicine_ball'),
  ('rope', 'jump_rope'),
  ('DU rope', 'jump_rope')

ON CONFLICT (alias) DO NOTHING;

-- Add comments
COMMENT ON TABLE zamm.lib_equipment_catalog IS 
'Master catalog of gym equipment. Contains canonical equipment_key and display names.';

COMMENT ON TABLE zamm.lib_equipment_aliases IS 
'Alternative names for equipment. Maps common variations (C2, DB, KB) to canonical keys.';

COMMENT ON COLUMN zamm.lib_equipment_catalog.equipment_key IS 
'Canonical identifier for equipment type (e.g., barbell, dumbbell, rowing_machine)';

COMMENT ON COLUMN zamm.lib_equipment_catalog.category IS 
'Equipment category: free_weights, cardio, machines, bodyweight, bands, mobility, functional, specialty';
