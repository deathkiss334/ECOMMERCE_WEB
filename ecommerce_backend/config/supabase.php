<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Supabase Project Configuration
    |--------------------------------------------------------------------------
    |
    | Set these values in your .env file from your Supabase project's
    | Settings → API page. The key should be the service_role key (not anon)
    | so Laravel can bypass Row Level Security when syncing data.
    |
    | The sync_enabled flag lets you disable REST API pushes without
    | removing the integration (useful for local offline development).
    |
    */

    'url'          => env('SUPABASE_URL', ''),
    'key'          => env('SUPABASE_KEY', ''),
    'rest_url'     => env('SUPABASE_URL', '') . '/rest/v1',
    'sync_enabled' => env('SUPABASE_SYNC_ENABLED', true),
];
