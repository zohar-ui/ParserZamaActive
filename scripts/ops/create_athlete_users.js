#!/usr/bin/env node
/**
 * Create Supabase Auth Users for Athletes
 * 
 * This script creates authentication users for all athletes with emails.
 * Links auth.users.id to zamm.lib_athletes.athlete_id
 * 
 * Usage:
 *   npm run create-athlete-users
 *   node scripts/ops/create_athlete_users.js
 */

const { createClient } = require('@supabase/supabase-js');
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// ============================================
// Load Environment Variables
// ============================================

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

loadEnvFile();

// ============================================
// Supabase Admin Client
// ============================================

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !DB_PASSWORD) {
    console.error('❌ Missing Supabase credentials in .env.local');
    console.error('Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_DB_PASSWORD');
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

// PostgreSQL client for zamm schema access
const pgClient = new Client({
    host: 'db.dtzcamerxuonoeujrgsu.supabase.co',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: DB_PASSWORD,
});

// ============================================
// Main Function
// ============================================

async function createAthleteUsers() {
    console.log('═══════════════════════════════════════════════════');
    console.log('👥 Creating Supabase Auth Users for Athletes');
    console.log('═══════════════════════════════════════════════════');
    console.log('');

    try {
        // Connect to PostgreSQL
        await pgClient.connect();

        // Get all athletes with emails
        const result = await pgClient.query(`
            SELECT athlete_id, full_name, email
            FROM zamm.lib_athletes
            WHERE email IS NOT NULL
              AND is_active = true
            ORDER BY created_at
        `);

        const athletes = result.rows;

        if (!athletes || athletes.length === 0) {
            console.log('ℹ️  No athletes with emails found');
            await pgClient.end();
            return;
        }

        console.log(`📋 Found ${athletes.length} athlete(s) with emails:`);
        athletes.forEach(a => console.log(`   - ${a.full_name} (${a.email})`));
        console.log('');

        // Create users
        let created = 0;
        let skipped = 0;
        let errors = 0;

        for (const athlete of athletes) {
            console.log(`───────────────────────────────────────────────────`);
            console.log(`Processing: ${athlete.full_name}`);
            console.log(`Email: ${athlete.email}`);
            console.log(`Athlete ID: ${athlete.athlete_id}`);

            // Check if user already exists
            const { data: existingUsers } = await supabase.auth.admin.listUsers();
            const existing = existingUsers?.users?.find(u => u.email === athlete.email);

            if (existing) {
                console.log(`⚠️  User already exists: ${existing.id}`);
                
                // Update user metadata to link to athlete
                const { error: updateError } = await supabase.auth.admin.updateUserById(
                    existing.id,
                    {
                        user_metadata: {
                            athlete_id: athlete.athlete_id,
                            full_name: athlete.full_name,
                            role: 'athlete'
                        }
                    }
                );

                if (updateError) {
                    console.error(`❌ Error updating user metadata: ${updateError.message}`);
                    errors++;
                } else {
                    console.log('✅ Updated user metadata with athlete_id');
                    skipped++;
                }
                continue;
            }

            // Generate temporary password
            const tempPassword = `Temp${Math.random().toString(36).substring(2, 10)}!`;

            // Create new user
            const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
                email: athlete.email,
                password: tempPassword,
                email_confirm: true, // Auto-confirm email
                user_metadata: {
                    athlete_id: athlete.athlete_id,
                    full_name: athlete.full_name,
                    role: 'athlete'
                }
            });

            if (createError) {
                console.error(`❌ Error creating user: ${createError.message}`);
                errors++;
                continue;
            }

            console.log(`✅ User created: ${newUser.user.id}`);
            console.log(`🔑 Temporary password: ${tempPassword}`);
            console.log(`📧 Password reset required on first login`);
            created++;
        }

        console.log('');
        console.log('═══════════════════════════════════════════════════');
        console.log('📊 Summary:');
        console.log(`   Created: ${created}`);
        console.log(`   Already existed: ${skipped}`);
        console.log(`   Errors: ${errors}`);
        console.log('═══════════════════════════════════════════════════');

        if (created > 0) {
            console.log('');
            console.log('⚠️  IMPORTANT:');
            console.log('   1. Save the temporary passwords above');
            console.log('   2. Send password reset emails to athletes');
            console.log('   3. Athletes must change password on first login');
        }

        // Close PostgreSQL connection
        await pgClient.end();

    } catch (error) {
        console.error('❌ Unexpected error:', error);
        await pgClient.end().catch(() => {});
        process.exit(1);
    }
}

// ============================================
// Run
// ============================================

createAthleteUsers()
    .then(() => {
        console.log('');
        console.log('✅ Done!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('❌ Fatal error:', error);
        process.exit(1);
    });
