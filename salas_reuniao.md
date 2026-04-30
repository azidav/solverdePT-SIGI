DB — 2 new tables (meeting_rooms, room_reservations) with 3 seed rooms.

Server API (8 files):

GET /api/meeting-rooms — public list with live occupancy status; ?all=true shows inactive rooms for managers
POST/PUT/DELETE /api/meeting-rooms[/id] — room CRUD, requires ROOMS:MANAGE
GET /api/room-reservations?date= — public list grouped by date, shows booker name
POST /api/room-reservations — auth users need ROOMS:RESERVE; guests just need a name; strict double-booking check
DELETE /api/room-reservations/:id — auth users cancel own; ROOMS:CANCEL_ANY cancels any; guests need their booking_token (valid ≤10 min)
Frontend (7 files):

layouts/booking.vue — public layout with header, "Entrar" for guests, user info + Dashboard link for auth
composables/useGuestToken.ts — localStorage token store with auto-expiry
pages/meeting-rooms/index.vue — public booking page: room cards with live status, day schedule inline, booking modal, cancel buttons visible per permission/token
pages/meeting-rooms/manage/{index,new,[id]}.vue — room management using default layout
