#!/usr/bin/env node
/**
 * Athlete Registration Script
 *
 * Usage:
 *   npm run create-athlete "Full Name" [email] [phone] [gender]
 *   node scripts/ops/create_athlete.js "Full Name" [email] [phone] [gender]
 *
 * Examples:
 *   npm run create-athlete "John Doe"
 *   npm run create-athlete "Jane Smith" "jane@example.com"
 *   npm run create-athlete "Bob Johnson" "bob@example.com" "+1-555-0123" "male"
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// ============================================
// Configuration
// ============================================

// Detect environment (local vs production)
const isLocal = process.env.SUPABASE_LOCAL === 'true';

// Local Supabase configuration (from `supabase start`)
const LOCAL_SUPABASE_URL = 'http://127.0.0.1:54321';
const LOCAL_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

// Load environment variables from .env.local if not in environment
function loadEnvFile() {
    const envPath = path.join(__dirname, '../../.env.local');
    if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        envContent.split('\n').forEach(line => {
            const match = line.match(/^([^=]+)=(.*)$/);
            if (match && !process.env[match[1]]) {
                process.env[match[1]] = match[2].trim();
            }
        });
    }
}

// Load env if not local
if (!isLocal) {
    loadEnvFile();
}

// Select configuration based on environment
const SUPABASE_URL = isLocal ? LOCAL_SUPABASE_URL : process.env.SUPABASE_URL;
const SUPABASE_KEY = isLocal ? LOCAL_SUPABASE_ANON_KEY : process.env.SUPABASE_ANON_KEY;

// ============================================
// Supabase Client
// ============================================

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
    auth: {
        persistSession: false,
        autoRefreshToken: false,
    }
});

// ============================================
// Main Function
// ============================================

async function registerAthlete(fullName, email = null, phone = null, gender = 'unknown') {
    console.log('═══════════════════════════════════════════════════');
    console.log('🏃 Athlete Registration');
    console.log('═══════════════════════════════════════════════════');
    console.log(`Environment: ${isLocal ? 'Local' : 'Production'}`);
    console.log(`URL: ${SUPABASE_URL}`);
    console.log('───────────────────────────────────────────────────');
    console.log(`Name:   ${fullName}`);
    if (email) console.log(`Email:  ${email}`);
    if (phone) console.log(`Phone:  ${phone}`);
    if (gender !== 'unknown') console.log(`Gender: ${gender}`);
    console.log('═══════════════════════════════════════════════════');
    console.log('');

    try {
        // Call the RPC function (wrapper in public schema)
        const { data, error } = await supabase
            .rpc('register_new_athlete', {
                p_full_name: fullName,
                p_email: email,
                p_phone: phone,
                p_gender: gender,
                p_data_source: 'cli_script'
            });

        if (error) {
            console.error('❌ Error:', error.message);
            console.error('Details:', error);
            process.exit(1);
        }

        // Extract result (RPC returns array of rows)
        const result = data && data.length > 0 ? data[0] : null;

        if (!result) {
            console.error('❌ No result returned from registration function');
            process.exit(1);
        }

        // Display results
        console.log('✅ Success!');
        console.log('');
        console.log('Result:');
        console.log(`  Athlete ID: ${result.athlete_id}`);
        console.log(`  Status:     ${result.is_new ? 'NEW' : 'EXISTING'}`);
        console.log(`  Message:    ${result.message}`);
        console.log('');

        if (result.is_new) {
            console.log('🎉 New athlete successfully registered!');
        } else {
            console.log('ℹ️  Athlete already exists (idempotent operation)');
        }

        console.log('═══════════════════════════════════════════════════');

        // Exit with code 0 for success
        process.exit(0);

    } catch (err) {
        console.error('❌ Unexpected error:', err.message);
        console.error(err);
        process.exit(1);
    }
}

// ============================================
// CLI Argument Parsing
// ============================================

function showUsage() {
    console.log('Usage: npm run create-athlete "Full Name" [email] [phone] [gender]');
    console.log('');
    console.log('Arguments:');
    console.log('  Full Name   (required)  Athlete\'s full name');
    console.log('  email       (optional)  Email address');
    console.log('  phone       (optional)  Phone number');
    console.log('  gender      (optional)  Gender (male/female/other/unknown)');
    console.log('');
    console.log('Examples:');
    console.log('  npm run create-athlete "John Doe"');
    console.log('  npm run create-athlete "Jane Smith" "jane@example.com"');
    console.log('  npm run create-athlete "Bob Johnson" "bob@example.com" "+1-555-0123" "male"');
    console.log('');
    console.log('Environment:');
    console.log('  Set SUPABASE_LOCAL=true to use local Supabase instance');
    console.log('  Otherwise uses production config from .env.local');
    process.exit(1);
}

// Parse command line arguments
const args = process.argv.slice(2);

if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    showUsage();
}

const [fullName, email, phone, gender] = args;

if (!fullName || fullName.trim() === '') {
    console.error('❌ Error: Full name is required');
    console.error('');
    showUsage();
}

// Run the registration
registerAthlete(fullName, email, phone, gender);
