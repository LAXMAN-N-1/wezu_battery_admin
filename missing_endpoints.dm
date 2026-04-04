# Missing Endpoints & Technical Debt Report
Project: wezu_battery_admin

This document lists the missing, mocked, or hardcoded endpoints across the User Management module screens.

## 1. User Management (Users View)
**File:** `lib/features/users/view/users_view.dart`
*   **Mocked:** `UserRepository.getCreationHistory()` is entirely mocked with hardcoded data.
*   **Unverified:** `deleteUser` and `changePassword` endpoints are used but have developer notes questioning their existence on the backend.
*   **Missing:** Invite management actions (resend/revoke) are implemented only in local state; they lack repository methods and backend endpoints.

## 2. User Analytics
**File:** `lib/features/users/view/user_analytics_view.dart`
*   **Mocked Repositories:** `getFraudRisks`, `getSuspensionHistory`, and `getInviteLinks` in `AnalyticsRepository` are completely mocked.
*   **Hardcoded UI Data:** Almost all charts (Growth, Revenue, Battery Health, etc.) use hardcoded data points directly in the View's build methods.

## 3. Suspended Accounts
**File:** `lib/features/users/view/suspended_accounts_view.dart`
*   **Mocked:** Relies on `AnalyticsRepository.getSuspensionHistory()`, which is mocked.
*   **Partial:** Reactivation is connected, but the history view will show fake data until the repo is updated.

## 4. Fraud Risk Monitoring
**File:** `lib/features/users/view/fraud_risk_view.dart`
*   **Hardcoded:** Device fingerprint risk scores (85%) and "First Seen" dates are hardcoded in the UI.
*   **Incomplete Logic:** The verification forms for PAN, GST, and Phone numbers have UI elements but no implementation in their button handlers.

## 5. Roles & Permissions
**File:** `lib/features/users/view/roles_permissions_view.dart`
*   **Architecture Debt:** The permission matrix and categories rely on a local cache in `RoleRepository` which must be manually populated by calling `getPermissions()` first.

## 6. Bulk Operations
**File:** `lib/features/users/view/bulk_operations_view.dart`
*   **Mocked/Incomplete:** Export functionality fetches data from the backend but lacks the logic to save it as a physical file on the user's machine (requires `path_provider`).
*   **Unverified:** Personalization tokens (`{{name}}`) are used in the UI, but backend support for these placeholders in the bulk messaging service is unconfirmed.

## 7. Session Activity
**File:** `lib/features/users/view/session_activity_view.dart`
*   **Mocked:** The "Export" button is a pure UI placeholder with a SnackBar.
*   **Hardcoded Metadata:** `getActionTypes()` and `getModules()` are hardcoded in the `AuditLogRepository`.
*   **Local Calculation:** Summary metrics (Total Events, Logins, etc.) are calculated from the current list in memory, which fails for paginated data.

## 8. KYC Dashboard & Verification
**Files:** `kyc_dashboard_view.dart`, `kyc_verification_view.dart`
*   **Status:** Mostly connected to real endpoints, but the backend implementation for the dashboard metrics and trend aggregation should be verified.

## 9. General Audit Log
**File:** `audit_log_repository.dart`
*   **Hardcoded:** Action categories and operational modules are represented as static lists in the repository rather than being dynamic.
