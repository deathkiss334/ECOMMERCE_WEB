<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DasmaBITES — SQLite Database Viewer</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-main: #0B0F19;
            --bg-card: #111827;
            --bg-hover: #1F2937;
            --border-color: #374151;
            --brand-primary: #FF6600;
            --brand-glow: rgba(255, 102, 0, 0.15);
            --text-main: #F3F4F6;
            --text-muted: #9CA3AF;
            --badge-green: #10B981;
            --badge-blue: #3B82F6;
            --badge-yellow: #F59E0B;
            --badge-red: #EF4444;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-main);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        header {
            background-color: var(--bg-card);
            border-bottom: 1px solid var(--border-color);
            padding: 14px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .brand-logo {
            display: flex;
            align-items: center;
            gap: 12px;
            text-decoration: none;
            color: var(--text-main);
        }

        .brand-badge {
            background: linear-gradient(135deg, #FF6600, #E65100);
            color: white;
            font-weight: 700;
            font-size: 14px;
            padding: 6px 12px;
            border-radius: 8px;
            letter-spacing: 0.5px;
        }

        .app-title {
            font-size: 16px;
            font-weight: 700;
            letter-spacing: -0.2px;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .btn-refresh {
            background-color: var(--bg-hover);
            color: var(--text-main);
            border: 1px solid var(--border-color);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-refresh:hover {
            border-color: var(--brand-primary);
            color: var(--brand-primary);
        }

        .layout-container {
            display: flex;
            flex: 1;
            overflow: hidden;
            height: calc(100vh - 61px);
        }

        /* Sidebar Tables List */
        .sidebar {
            width: 260px;
            background-color: #0E1424;
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            flex-shrink: 0;
        }

        .sidebar-header {
            padding: 16px;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            color: var(--text-muted);
            border-bottom: 1px solid var(--border-color);
        }

        .table-list {
            list-style: none;
            overflow-y: auto;
            flex: 1;
            padding: 8px;
        }

        .table-item {
            margin-bottom: 4px;
        }

        .table-link {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            border-radius: 8px;
            color: var(--text-muted);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.15s ease;
        }

        .table-link:hover {
            background-color: var(--bg-hover);
            color: var(--text-main);
        }

        .table-link.active {
            background-color: var(--brand-glow);
            color: var(--brand-primary);
            font-weight: 600;
            border-left: 3px solid var(--brand-primary);
        }

        /* Main Content View */
        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            background-color: var(--bg-main);
        }

        .toolbar {
            padding: 16px 24px;
            background-color: var(--bg-card);
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 16px;
        }

        .toolbar-left {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .table-title {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-main);
        }

        .count-badge {
            background-color: var(--bg-hover);
            border: 1px solid var(--border-color);
            padding: 3px 9px;
            border-radius: 12px;
            font-size: 12px;
            color: var(--text-muted);
        }

        .search-form {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .search-input {
            background-color: var(--bg-main);
            border: 1px solid var(--border-color);
            color: var(--text-main);
            padding: 8px 14px;
            border-radius: 8px;
            font-size: 13px;
            width: 240px;
            outline: none;
            transition: border-color 0.2s;
        }

        .search-input:focus {
            border-color: var(--brand-primary);
        }

        .btn-search {
            background-color: var(--brand-primary);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s;
        }

        .btn-search:hover {
            opacity: 0.9;
        }

        .btn-clear {
            background-color: var(--bg-hover);
            color: var(--text-muted);
            border: 1px solid var(--border-color);
            padding: 8px 12px;
            border-radius: 8px;
            font-size: 13px;
            text-decoration: none;
        }

        /* Schema Drawer */
        .schema-bar {
            padding: 10px 24px;
            background-color: #0E1424;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            gap: 10px;
            overflow-x: auto;
            white-space: nowrap;
        }

        .schema-title {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--text-muted);
        }

        .column-tag {
            font-family: 'JetBrains Mono', monospace;
            font-size: 11px;
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            padding: 3px 8px;
            border-radius: 6px;
            color: #93C5FD;
        }

        .column-type {
            color: #6EE7B7;
            font-size: 10px;
        }

        /* Data Table */
        .table-responsive {
            flex: 1;
            overflow: auto;
            padding: 20px 24px;
        }

        .data-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            font-size: 13px;
            text-align: left;
        }

        .data-table th {
            background-color: #161F30;
            color: var(--text-muted);
            font-weight: 600;
            padding: 12px 16px;
            border-bottom: 1px solid var(--border-color);
            border-top: 1px solid var(--border-color);
            position: sticky;
            top: -20px;
            z-index: 10;
            white-space: nowrap;
        }

        .data-table td {
            padding: 12px 16px;
            border-bottom: 1px solid rgba(55, 65, 81, 0.4);
            color: var(--text-main);
            vertical-align: middle;
            max-width: 320px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .data-table tbody tr:hover {
            background-color: rgba(31, 41, 55, 0.6);
        }

        /* Status Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 0.3px;
        }

        .badge-pending { background-color: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
        .badge-awaiting { background-color: rgba(59, 130, 246, 0.15); color: #60A5FA; border: 1px solid rgba(59, 130, 246, 0.3); }
        .badge-preparing { background-color: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
        .badge-delivery { background-color: rgba(139, 92, 246, 0.15); color: #A78BFA; border: 1px solid rgba(139, 92, 246, 0.3); }
        .badge-delivered { background-color: rgba(16, 185, 129, 0.25); color: #10B981; border: 1px solid #10B981; }
        .badge-rejected { background-color: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239, 68, 68, 0.3); }

        .image-thumb {
            width: 44px;
            height: 44px;
            border-radius: 6px;
            object-fit: cover;
            border: 1px solid var(--border-color);
            cursor: pointer;
            transition: transform 0.15s;
        }

        .image-thumb:hover {
            transform: scale(1.15);
        }

        .sql-box {
            padding: 16px 24px;
            background-color: var(--bg-card);
            border-top: 1px solid var(--border-color);
        }

        .sql-input {
            width: 100%;
            background-color: var(--bg-main);
            border: 1px solid var(--border-color);
            color: #A7F3D0;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            padding: 10px 14px;
            border-radius: 8px;
            resize: vertical;
            outline: none;
            margin-bottom: 8px;
        }

        .sql-input:focus {
            border-color: var(--brand-primary);
        }

        .empty-state {
            padding: 60px 20px;
            text-align: center;
            color: var(--text-muted);
        }

        .alert-error {
            background-color: rgba(239, 68, 68, 0.15);
            border: 1px solid var(--badge-red);
            color: #FCA5A5;
            padding: 12px 20px;
            border-radius: 8px;
            margin: 16px 24px;
            font-size: 13px;
        }
    </style>
</head>
<body>

    <header>
        <a href="/db-viewer" class="brand-logo">
            <span class="brand-badge">DasmaBITES</span>
            <span class="app-title">Live SQLite Database Viewer</span>
        </a>
        <div class="header-actions">
            <a href="/db-viewer?table={{ $currentTable }}" class="btn-refresh">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
                Refresh Data
            </a>
            <a href="/admin/orders" class="btn-refresh" target="_blank" style="border-color: var(--brand-primary); color: var(--brand-primary);">
                Open Order Management
            </a>
        </div>
    </header>

    @if($error)
        <div class="alert-error">
            <strong>Database Notice:</strong> {{ $error }}
        </div>
    @endif

    <div class="layout-container">
        <!-- Sidebar: Table Navigator -->
        <aside class="sidebar">
            <div class="sidebar-header">Database Tables ({{ count($tableNames) }})</div>
            <ul class="table-list">
                @foreach($tableNames as $tbl)
                    <li class="table-item">
                        <a href="/db-viewer?table={{ $tbl }}" class="table-link {{ $tbl === $currentTable ? 'active' : '' }}">
                            <span>
                                @if($tbl === 'orders') 📦
                                @elseif($tbl === 'order_chats') 💬
                                @elseif($tbl === 'order_reviews') ⭐
                                @elseif($tbl === 'products') 🍔
                                @elseif($tbl === 'users') 👤
                                @elseif($tbl === 'payments') 💳
                                @else 📋
                                @endif
                                {{ $tbl }}
                            </span>
                        </a>
                    </li>
                @endforeach
            </ul>
        </aside>

        <!-- Main View: Table Records -->
        <main class="main-content">
            <div class="toolbar">
                <div class="toolbar-left">
                    <span class="table-title">{{ $currentTable }}</span>
                    <span class="count-badge">{{ number_format($totalCount) }} records</span>
                </div>

                <form method="GET" action="/db-viewer" class="search-form">
                    <input type="hidden" name="table" value="{{ $currentTable }}">
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="Search {{ $currentTable }}..." class="search-input">
                    <button type="submit" class="btn-search">Search</button>
                    @if(request('search'))
                        <a href="/db-viewer?table={{ $currentTable }}" class="btn-clear">Clear</a>
                    @endif
                </form>
            </div>

            <!-- Columns Schema Inspector -->
            @if(!empty($columns))
                <div class="schema-bar">
                    <span class="schema-title">Columns:</span>
                    @foreach($columns as $col)
                        <span class="column-tag">
                            {{ $col->name }} <span class="column-type">({{ $col->type }})</span>
                        </span>
                    @endforeach
                </div>
            @endif

            <!-- Data Table Grid -->
            <div class="table-responsive">
                @if(count($rows) > 0)
                    <table class="data-table">
                        <thead>
                            <tr>
                                @foreach($columns as $col)
                                    <th>{{ $col->name }}</th>
                                @endforeach
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($rows as $row)
                                <tr>
                                    @foreach($columns as $col)
                                        @php
                                            $colName = $col->name;
                                            $val = $row->$colName ?? null;
                                        @endphp
                                        <td>
                                            @if($colName === 'status' || $colName === 'payment_status')
                                                @php $s = strtoupper((string)$val); @endphp
                                                <span class="badge 
                                                    @if($s === 'PREPARING' || $s === 'PAID') badge-preparing
                                                    @elseif($s === 'AWAITING_VERIFICATION') badge-awaiting
                                                    @elseif($s === 'OUT_FOR_DELIVERY' || $s === 'RIDER_ARRIVED') badge-delivery
                                                    @elseif($s === 'DELIVERED') badge-delivered
                                                    @elseif($s === 'PAYMENT_REJECTED' || $s === 'REJECTED' || $s === 'CANCELLED') badge-rejected
                                                    @else badge-pending
                                                    @endif">
                                                    {{ $val }}
                                                </span>
                                            @elseif(($colName === 'receipt_image_url' || $colName === 'product_img') && !empty($val))
                                                <a href="{{ $val }}" target="_blank">
                                                    <img src="{{ $val }}" class="image-thumb" alt="Receipt Proof" title="Click to view full image">
                                                </a>
                                            @elseif(is_numeric($val) && ($colName === 'total_amount' || $colName === 'subtotal' || $colName === 'base_price' || $colName === 'amount'))
                                                <strong>₱{{ number_format((float)$val, 2) }}</strong>
                                            @else
                                                {{ is_null($val) ? '—' : $val }}
                                            @endif
                                        </td>
                                    @endforeach
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                @else
                    <div class="empty-state">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 12px; opacity: 0.5;"><path d="M4 6h16M4 12h16m-7 6h7"/></svg>
                        <p>No records found in table <strong>{{ $currentTable }}</strong>.</p>
                    </div>
                @endif
            </div>

            <!-- SQL Query Sandbox Bar -->
            <div class="sql-box">
                <form method="GET" action="/db-viewer">
                    <input type="hidden" name="table" value="{{ $currentTable }}">
                    <textarea name="sql" rows="2" class="sql-input" placeholder="Execute read-only SQL: SELECT * FROM orders WHERE status = 'PREPARING' LIMIT 10;">{{ request('sql') }}</textarea>
                    <div style="display: flex; justify-content: flex-end; gap: 8px;">
                        <button type="submit" class="btn-search" style="background-color: #3B82F6;">Run SQL Query</button>
                    </div>
                </form>
            </div>
        </main>
    </div>

</body>
</html>
