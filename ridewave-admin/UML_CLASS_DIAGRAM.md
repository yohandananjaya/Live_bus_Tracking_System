# Bus Tracker Admin Panel - UML Class Diagram

## PlantUML Diagram

```plantuml
@startuml BusTrackerAdminPanel

!define ABSTRACT abstract
!define INTERFACE interface
!define ENUM enum

' === CONTEXT & STATE ===

class AuthContext {
  - user: User | null
  - isAuthenticated: boolean
  
  + signIn(email: string, password: string): void
  + signInWithGoogle(): void
  + signOut(): void
}

class User {
  - email: string
  - provider?: string
}

' === PAGE COMPONENTS ===

ABSTRACT class PageComponent {
  # title: string
  # data: any[]
  
  + render(): JSX.Element
}

class Dashboard extends PageComponent {
  - busData: Bus[]
  - alerts: Alert[]
  - vehicleCoordinates: GeoLocation[]
  
  + displayBusStatus(): void
  + showBusDetails(busNo: string): void
}

class Buses extends PageComponent {
  - buses: Bus[]
  - query: string
  - statusFilter: string
  - sortBy: string
  - draft: Bus
  
  + filterBuses(): Bus[]
  + sortBuses(criterion: string): Bus[]
  + addBus(bus: Bus): void
  + deleteBus(id: string): void
  + validateBusForm(): boolean
}

class Routes extends PageComponent {
  - routes: Route[]
  - editingId?: string
  - draft: Route
  
  + createRoute(route: Route): void
  + editRoute(id: string, route: Route): void
  + deleteRoute(id: string): void
  + validateRouteForm(): boolean
}

class Alerts extends PageComponent {
  - alerts: Alert[]
  
  + displayAlerts(): void
  + handleAlert(alert: Alert): void
}

class LiveMap extends PageComponent {
  - mapCenter: GeoLocation
  - vehicleMarkers: MapMarker[]
  
  + renderMap(): void
  + updateVehicleLocation(location: GeoLocation): void
}

class SignIn extends PageComponent {
  - email: string
  - password: string
  
  + handleLogin(): void
  + handleGoogleLogin(): void
}

class SignUp extends PageComponent {
  - email: string
  - password: string
  - confirmPassword: string
  
  + handleRegister(): void
}

' === LAYOUT COMPONENTS ===

class Layout {
  - menuOpen: boolean
  - reportOpen: boolean
  - reportType: string
  - reportMode: string
  - reportData: ReportData
  - exporting: boolean
  
  + renderSidebar(): JSX.Element
  + renderMainContent(): JSX.Element
  + handleSignOut(): void
  + exportReport(type: string, format: string): void
}

class Sidebar {
  - navItems: NavItem[]
  - userName: string
  - appVersion: string
  
  + renderNavigation(): JSX.Element
  + renderUserCard(): JSX.Element
  + handleNavigate(): void
}

' === DATA MODELS ===

class Bus {
  - id: string
  - no: string
  - route: string
  - driver: string
  - passengers: number
  - status: string
  - lastStop: string
  - eta: string
  - currentLocation: string
  - coords: [number, number]
  - online: boolean
}

class Route {
  - id: string
  - name: string
  - busNo: string
  - path: string
  - status: string
}

class Alert {
  - id: string
  - busNo: string
  - severity: string
  - status: string
  - authority: string
  - message: string
  - timestamp: Date
}

class GeoLocation {
  - latitude: number
  - longitude: number
  - timestamp: Date
  - accuracy: number
}

class MapMarker {
  - id: string
  - busNo: string
  - location: GeoLocation
  - icon: string
}

class ReportData {
  - summary: any[][]
  - full: any[][]
  - reportType: string
  - generatedDate: Date
}

class NavItem {
  - to: string
  - label: string
}

class SummaryMetric {
  - metric: string
  - value: string
}

' === RELATIONSHIPS ===

' AuthContext relationships
AuthContext --> User: manages
AuthContext *-- "0..1" User: contains

' Layout relationships
Layout --> Sidebar: contains
Layout --> "5" PageComponent: renders
Layout *-- ReportData: uses

' Sidebar relationships
Sidebar --> NavItem: displays
Sidebar --> User: displays

' Page relationships
Dashboard --> Bus: displays
Dashboard --> Alert: displays
Dashboard --> GeoLocation: uses

Buses --> Bus: manages
Buses *-- "0..5" Bus: contains

Routes --> Route: manages
Routes *-- "0..5" Route: contains

Alerts --> Alert: displays

LiveMap --> GeoLocation: tracks
LiveMap --> MapMarker: displays

SignIn --> User: creates
SignUp --> User: creates

' Data model relationships
Bus --> GeoLocation: has
Route --> Bus: routes
Alert --> Bus: references
MapMarker --> Bus: represents
MapMarker --> GeoLocation: uses

' Router relationships
note right of Dashboard
  Protected Route
  Requires Authentication
end note

note right of Buses
  Protected Route
  Requires Authentication
end note

note right of Routes
  Protected Route
  Requires Authentication
end note

note right of LiveMap
  Protected Route
  Requires Authentication
end note

note right of SignIn
  Public Route
  Public Only Route
end note

note right of SignUp
  Public Route
  Public Only Route
end note

@enduml
```

## Architecture Overview

### Component Hierarchy

```
App (Router)
├── Public Routes
│   ├── SignIn
│   └── SignUp
└── Protected Routes
    └── Layout
        ├── Sidebar
        └── MainContent
            ├── Dashboard
            ├── Buses
            ├── Routes
            ├── Alerts
            └── LiveMap
```

### State Management

- **AuthContext**: Manages user authentication state globally
- **Local State**: Each page component manages its own data (buses, routes, alerts)
- **Memoization**: Used for computed values (filtered/sorted data, summaries)

### Key Data Models

| Model | Purpose | Key Fields |
|-------|---------|-----------|
| **User** | Authentication | email, provider |
| **Bus** | Vehicle tracking | id, route, driver, status, coordinates, passengers |
| **Route** | Trip planning | id, name, busNo, path, status |
| **Alert** | Notifications | id, busNo, severity, status, authority |
| **GeoLocation** | GPS data | latitude, longitude, timestamp, accuracy |

### Features

1. **Authentication**: Sign in/up with email or Google
2. **Dashboard**: Real-time bus status, alerts, and metrics
3. **Fleet Management**: View and manage buses
4. **Route Management**: Create, edit, and manage routes
5. **Alerts System**: Monitor and respond to bus alerts
6. **Live Map**: Track vehicle locations in real-time
7. **Reporting**: Generate and export operational reports

---

*Diagram generated for Bus Tracker Admin Panel v0.0.0*
