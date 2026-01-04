#!/bin/bash
# Test Block Type System

echo "🧪 Testing Block Type Catalog..."
echo ""

echo "1️⃣ Count of block types:"
supabase db execute "SELECT COUNT(*) as total_blocks FROM zamm.block_type_catalog;" --format csv

echo ""
echo "2️⃣ Count of aliases:"
supabase db execute "SELECT COUNT(*) as total_aliases FROM zamm.block_code_aliases;" --format csv

echo ""
echo "3️⃣ Block types by category:"
supabase db execute "
SELECT 
    category, 
    COUNT(*) as block_count,
    STRING_AGG(block_code, ', ' ORDER BY sort_order) as codes
FROM zamm.block_type_catalog
GROUP BY category
ORDER BY MIN(sort_order);
" --format table

echo ""
echo "4️⃣ Test normalize_block_code() with various inputs:"
echo ""
echo "  Test: 'strength' →"
supabase db execute "SELECT block_code, display_name, ui_hint, matched_via FROM zamm.normalize_block_code('strength');" --format csv

echo ""
echo "  Test: 'כוח' (Hebrew) →"
supabase db execute "SELECT block_code, display_name, ui_hint, matched_via FROM zamm.normalize_block_code('כוח');" --format csv

echo ""
echo "  Test: 'wod' →"
supabase db execute "SELECT block_code, display_name, ui_hint, matched_via FROM zamm.normalize_block_code('wod');" --format csv

echo ""
echo "  Test: 'metcon' →"
supabase db execute "SELECT block_code, display_name, ui_hint, matched_via FROM zamm.normalize_block_code('metcon');" --format csv

echo ""
echo "5️⃣ UI Hints validation:"
supabase db execute "
SELECT DISTINCT ui_hint, COUNT(*) as usage_count
FROM zamm.block_type_catalog
GROUP BY ui_hint
ORDER BY ui_hint;
" --format table

echo ""
echo "6️⃣ Sample: STRENGTH category details:"
supabase db execute "
SELECT 
    block_code,
    display_name,
    result_model,
    ui_hint,
    icon
FROM zamm.block_type_catalog
WHERE category = 'strength'
ORDER BY sort_order;
" --format table

echo ""
echo "✅ Tests complete!"
