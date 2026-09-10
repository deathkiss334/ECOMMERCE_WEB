<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Firebase Project Configuration
    |--------------------------------------------------------------------------
    |
    | Set these values in your .env file once you create your Firebase project.
    | If left blank, the application will operate gracefully in offline/local
    | mode without throwing exceptions.
    |
    */
    'project_id' => env('FIREBASE_PROJECT_ID', ''),
    'credentials_path' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase/service-account.json')),
    'database_url' => env('FIREBASE_DATABASE_URL', ''),
    'sync_enabled' => env('FIREBASE_SYNC_ENABLED', true),
];
