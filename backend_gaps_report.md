# Backend Gaps & Infrastructure Requirements Report
Project: wezu_battery_admin (Admin Dashboard)

## Executive Summary
This report summarizes the missing API endpoints and backend functionalities identified during an audit of the User Management, Fraud, Analytics, and KYC modules. These gaps are currently handled by frontend mocks or hardcoded data.

---

## 1. User Management & Invites
| Gap / Missing Endpoint | Current State | Requirement |
| :--- | :--- | :--- |
| **User Creation History** | Mocked in `UserRepository` | `GET /api/v1/admin/users/creation-history` |
| **Delete User** | Integrated | `DELETE /api/v1/admin/users/{userId}` |
| **Password Reset (Admin)** | Integrated | `POST /api/v1/admin/users/{userId}/reset-password` |
| **Resend / Revoke Invite** | Local State Only | `POST /api/v1/admin/users/invite/{id}/resend` & `POST /api/v1/admin/users/invite/{id}/revoke` |
| **Invite History** | Local State Only | `GET /api/v1/admin/users/invites` (History view) |

---

## 2. User Analytics & KPIs
| Gap / Missing Endpoint | Current State | Status |
| :--- | :--- | :--- |
| **Platform Trends** | **Integrated** | `GET /api/v1/admin/analytics/trends` |
| **Conversion Funnels** | **Integrated** | `GET /api/v1/admin/analytics/conversion-funnel` |
| **User Behavior** | **Integrated** | `GET /api/v1/admin/analytics/user-behavior` |
| **Inventory Status** | **Integrated** | `GET /api/v1/admin/analytics/inventory-status` |
| **Revenue Breakdowns** | **Integrated** | By Region, Station, and Battery Type connected. |
| **Top Stations** | **Integrated** | `GET /api/v1/admin/analytics/top-stations` |
| **Fraud Risk Summary** | Mocked in `AnalyticsRepository` | `GET /api/v1/admin/analytics/fraud-risks` |
| **Suspension History (Global)** | Mocked in `AnalyticsRepository` | `GET /api/v1/admin/analytics/suspensions` |

---

## 3. Fraud & Risk Monitoring
| Gap / Missing Endpoint | Current State | Requirement |
| :--- | :--- | :--- |
| **Identity Verification** | **Integrated** | Connected to `/api/v1/admin/fraud/verify/{pan|gst|phone}` |
| **Device Fingerprint Scoring** | Hardcoded in `FraudRiskView` | `GET /api/v1/admin/fraud/fingerprints/{id}/score` (Real-time risk scoring). |

---

## 4. Operational Gaps (Audit & Bulk Ops)
| Gap / Missing Endpoint | Current State | Requirement |
| :--- | :--- | :--- |
| **Audit Metadata** | Hardcoded in Repo | `GET /api/v1/admin/audit/config` (Load Action Types & Module names). |
| **Audit Export** | Mocked in `SessionActivityView` | `POST /api/v1/admin/audit/export` (Trigger CSV/PDF export). |
| **Bulk Personalization** | Placeholder tokens (`{{name}}`) | Backend templating support for bulk messages (Email/SMS). |
| **Summary Calculations** | Local calculation in UI | Backend should provide total counts/aggregates (e.g., Total Logins, Total Modifications) to ensure accuracy with pagination. |

---

## 5. Roles & Permissions
*   **Dynamic Permissions:** The permission matrix currently relies on a client-side cache of fetched permissions. A more robust backend-driven roles/permissions discovery service would ensure consistency.

---

## Recommendations
1.  **Prioritize Analytics Endpoints**: The Analytics and KPI charts are currently static and do not reflect real system usage.
2.  **Verify Admin Write Endpoints**: Ensure `deleteUser` and `changePassword` endpoints match the required API spec and are not just conceptual placeholders.
3.  **Implement Audit Export**: For compliance and reporting, the audit log export is a critical missing piece of functionality.
