<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DbViewerController extends Controller
{
    public function index(Request $request)
    {
        // 1. Get all table names in SQLite
        $tables = DB::select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name ASC");
        $tableNames = array_map(fn($t) => $t->name, $tables);

        // Filter out framework internal tables if desired or keep them accessible
        $currentTable = $request->get('table', in_array('orders', $tableNames) ? 'orders' : ($tableNames[0] ?? ''));

        $columns = [];
        $rows = [];
        $totalCount = 0;
        $error = null;

        if ($currentTable && in_array($currentTable, $tableNames)) {
            try {
                // Table schema
                $columns = DB::select("PRAGMA table_info(\"{$currentTable}\")");

                // Search query
                $search = $request->get('search');
                $query = DB::table($currentTable);

                if ($search && !empty($columns)) {
                    $query->where(function ($q) use ($columns, $search) {
                        foreach ($columns as $col) {
                            $q->orWhere($col->name, 'LIKE', "%{$search}%");
                        }
                    });
                }

                $totalCount = $query->count();
                $rows = $query->orderBy(isset($columns[0]) ? $columns[0]->name : 'rowid', 'desc')
                    ->limit(100)
                    ->get();
            } catch (\Throwable $e) {
                $error = $e->getMessage();
            }
        }

        // Custom query runner (read-only SELECT for security)
        $customQuery = $request->get('sql');
        $customResults = null;
        if ($customQuery) {
            try {
                $trimmed = trim($customQuery);
                if (!preg_match('/^SELECT/i', $trimmed)) {
                    $error = "Only SELECT queries are allowed in the browser viewer.";
                } else {
                    $customResults = DB::select($trimmed);
                }
            } catch (\Throwable $e) {
                $error = "SQL Error: " . $e->getMessage();
            }
        }

        return view('db_viewer', compact('tableNames', 'currentTable', 'columns', 'rows', 'totalCount', 'error', 'customQuery', 'customResults'));
    }
}
