--
-- PostgreSQL database dump
--

\restrict d2lYggnPZbEaOj0C6ZnCGcp3gjbLWePHOmJnaEJ7KJLvaT39HCFIbkQcLroGcFh

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: approval_level_members; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.approval_level_members (
    id integer NOT NULL,
    level_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.approval_level_members OWNER TO azidav;

--
-- Name: approval_level_members_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.approval_level_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.approval_level_members_id_seq OWNER TO azidav;

--
-- Name: approval_level_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.approval_level_members_id_seq OWNED BY public.approval_level_members.id;


--
-- Name: approval_levels; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.approval_levels (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    step_order integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    parent_id integer,
    is_rh boolean DEFAULT false NOT NULL
);


ALTER TABLE public.approval_levels OWNER TO azidav;

--
-- Name: approval_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.approval_levels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.approval_levels_id_seq OWNER TO azidav;

--
-- Name: approval_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.approval_levels_id_seq OWNED BY public.approval_levels.id;


--
-- Name: approval_workflow_config; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.approval_workflow_config (
    id integer NOT NULL,
    step_order integer NOT NULL,
    role_name character varying(100) NOT NULL,
    required_permission character varying(100) DEFAULT 'VACATION:APPROVE'::character varying NOT NULL,
    skip_after_hours integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.approval_workflow_config OWNER TO azidav;

--
-- Name: approval_workflow_config_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.approval_workflow_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.approval_workflow_config_id_seq OWNER TO azidav;

--
-- Name: approval_workflow_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.approval_workflow_config_id_seq OWNED BY public.approval_workflow_config.id;


--
-- Name: approval_workflow_steps; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.approval_workflow_steps (
    id integer NOT NULL,
    request_id integer NOT NULL,
    step_order integer NOT NULL,
    approver_id integer,
    role_name character varying(100) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    comment text,
    actioned_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    level_id integer
);


ALTER TABLE public.approval_workflow_steps OWNER TO azidav;

--
-- Name: approval_workflow_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.approval_workflow_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.approval_workflow_steps_id_seq OWNER TO azidav;

--
-- Name: approval_workflow_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.approval_workflow_steps_id_seq OWNED BY public.approval_workflow_steps.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id integer,
    user_name character varying(150),
    action character varying(50) NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id integer,
    entity_name character varying(255),
    old_values jsonb,
    new_values jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO azidav;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO azidav;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: blackout_dates; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.blackout_dates (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    reason text,
    department character varying(100),
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.blackout_dates OWNER TO azidav;

--
-- Name: blackout_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.blackout_dates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blackout_dates_id_seq OWNER TO azidav;

--
-- Name: blackout_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.blackout_dates_id_seq OWNED BY public.blackout_dates.id;


--
-- Name: config_variables; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.config_variables (
    id integer NOT NULL,
    section character varying(100) NOT NULL,
    key character varying(100) NOT NULL,
    label character varying(255) NOT NULL,
    value text DEFAULT ''::text,
    is_secret boolean DEFAULT false,
    description character varying(500),
    input_type character varying(50) DEFAULT 'text'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.config_variables OWNER TO azidav;

--
-- Name: config_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.config_variables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.config_variables_id_seq OWNER TO azidav;

--
-- Name: config_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.config_variables_id_seq OWNED BY public.config_variables.id;


--
-- Name: leave_balances; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.leave_balances (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    year integer NOT NULL,
    base_days integer DEFAULT 22 NOT NULL,
    seniority_bonus integer DEFAULT 0 NOT NULL,
    birthday_bonus integer DEFAULT 0 NOT NULL,
    used_days numeric(4,1) DEFAULT 0 NOT NULL,
    pending_days numeric(4,1) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    carryover_days numeric(4,1) DEFAULT 0 NOT NULL
);


ALTER TABLE public.leave_balances OWNER TO azidav;

--
-- Name: leave_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.leave_balances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.leave_balances_id_seq OWNER TO azidav;

--
-- Name: leave_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.leave_balances_id_seq OWNED BY public.leave_balances.id;


--
-- Name: meeting_rooms; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.meeting_rooms (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    image_url character varying(500),
    capacity integer DEFAULT 0,
    location character varying(200),
    amenities text,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.meeting_rooms OWNER TO azidav;

--
-- Name: meeting_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.meeting_rooms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.meeting_rooms_id_seq OWNER TO azidav;

--
-- Name: meeting_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.meeting_rooms_id_seq OWNED BY public.meeting_rooms.id;


--
-- Name: msgraph_subscriptions; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.msgraph_subscriptions (
    id integer NOT NULL,
    subscription_id character varying(255) NOT NULL,
    room_id integer,
    resource_email character varying(255) NOT NULL,
    expiration_datetime timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.msgraph_subscriptions OWNER TO azidav;

--
-- Name: msgraph_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.msgraph_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.msgraph_subscriptions_id_seq OWNER TO azidav;

--
-- Name: msgraph_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.msgraph_subscriptions_id_seq OWNED BY public.msgraph_subscriptions.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.password_reset_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.password_reset_tokens OWNER TO azidav;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_reset_tokens_id_seq OWNER TO azidav;

--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    code character varying(100) NOT NULL,
    description text NOT NULL,
    module character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.permissions OWNER TO azidav;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissions_id_seq OWNER TO azidav;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.positions (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    parent_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.positions OWNER TO azidav;

--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.positions_id_seq OWNER TO azidav;

--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.positions_id_seq OWNED BY public.positions.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO azidav;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.roles OWNER TO azidav;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO azidav;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: room_graph_mappings; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.room_graph_mappings (
    id integer NOT NULL,
    room_id integer NOT NULL,
    resource_email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.room_graph_mappings OWNER TO azidav;

--
-- Name: room_graph_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.room_graph_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.room_graph_mappings_id_seq OWNER TO azidav;

--
-- Name: room_graph_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.room_graph_mappings_id_seq OWNED BY public.room_graph_mappings.id;


--
-- Name: room_reservations; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.room_reservations (
    id integer NOT NULL,
    room_id integer NOT NULL,
    user_id integer,
    guest_name character varying(150),
    booking_token character varying(255),
    token_expires_at timestamp with time zone,
    meeting_title character varying(255) NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    description text,
    ical_uid text,
    change_key text,
    graph_event_id text,
    source character varying(20) DEFAULT 'platform'::character varying
);


ALTER TABLE public.room_reservations OWNER TO azidav;

--
-- Name: room_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.room_reservations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.room_reservations_id_seq OWNER TO azidav;

--
-- Name: room_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.room_reservations_id_seq OWNED BY public.room_reservations.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer
);


ALTER TABLE public.user_roles OWNER TO azidav;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_id_seq OWNER TO azidav;

--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100) NOT NULL,
    password character varying(255),
    name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    department character varying(100),
    role_id integer,
    permission integer DEFAULT 2,
    status integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    must_change_password boolean DEFAULT false NOT NULL,
    job_title character varying(150),
    hire_date date,
    birthday date,
    position_id integer,
    employee_no character varying(50)
);


ALTER TABLE public.users OWNER TO azidav;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO azidav;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vacation_request_history; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.vacation_request_history (
    id integer NOT NULL,
    request_id integer NOT NULL,
    actor_id integer,
    actor_name character varying(150),
    old_status character varying(20),
    new_status character varying(20),
    step_order integer,
    comment text,
    actioned_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.vacation_request_history OWNER TO azidav;

--
-- Name: vacation_request_history_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.vacation_request_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vacation_request_history_id_seq OWNER TO azidav;

--
-- Name: vacation_request_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.vacation_request_history_id_seq OWNED BY public.vacation_request_history.id;


--
-- Name: vacation_requests; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.vacation_requests (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    type character varying(50) DEFAULT 'annual'::character varying NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    days_count numeric(4,1) NOT NULL,
    reason text,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    current_approval_step integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    half_day boolean DEFAULT false NOT NULL,
    processed_externally boolean DEFAULT false NOT NULL
);


ALTER TABLE public.vacation_requests OWNER TO azidav;

--
-- Name: vacation_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.vacation_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vacation_requests_id_seq OWNER TO azidav;

--
-- Name: vacation_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.vacation_requests_id_seq OWNED BY public.vacation_requests.id;


--
-- Name: vacation_types; Type: TABLE; Schema: public; Owner: azidav
--

CREATE TABLE public.vacation_types (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    code character varying(50) NOT NULL,
    uses_balance boolean DEFAULT true NOT NULL,
    requires_approval_chain boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.vacation_types OWNER TO azidav;

--
-- Name: vacation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: azidav
--

CREATE SEQUENCE public.vacation_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vacation_types_id_seq OWNER TO azidav;

--
-- Name: vacation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: azidav
--

ALTER SEQUENCE public.vacation_types_id_seq OWNED BY public.vacation_types.id;


--
-- Name: approval_level_members id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_level_members ALTER COLUMN id SET DEFAULT nextval('public.approval_level_members_id_seq'::regclass);


--
-- Name: approval_levels id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_levels ALTER COLUMN id SET DEFAULT nextval('public.approval_levels_id_seq'::regclass);


--
-- Name: approval_workflow_config id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_config ALTER COLUMN id SET DEFAULT nextval('public.approval_workflow_config_id_seq'::regclass);


--
-- Name: approval_workflow_steps id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_steps ALTER COLUMN id SET DEFAULT nextval('public.approval_workflow_steps_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: blackout_dates id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.blackout_dates ALTER COLUMN id SET DEFAULT nextval('public.blackout_dates_id_seq'::regclass);


--
-- Name: config_variables id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.config_variables ALTER COLUMN id SET DEFAULT nextval('public.config_variables_id_seq'::regclass);


--
-- Name: leave_balances id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.leave_balances ALTER COLUMN id SET DEFAULT nextval('public.leave_balances_id_seq'::regclass);


--
-- Name: meeting_rooms id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.meeting_rooms ALTER COLUMN id SET DEFAULT nextval('public.meeting_rooms_id_seq'::regclass);


--
-- Name: msgraph_subscriptions id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.msgraph_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.msgraph_subscriptions_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: positions id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.positions ALTER COLUMN id SET DEFAULT nextval('public.positions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: room_graph_mappings id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_graph_mappings ALTER COLUMN id SET DEFAULT nextval('public.room_graph_mappings_id_seq'::regclass);


--
-- Name: room_reservations id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_reservations ALTER COLUMN id SET DEFAULT nextval('public.room_reservations_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vacation_request_history id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_request_history ALTER COLUMN id SET DEFAULT nextval('public.vacation_request_history_id_seq'::regclass);


--
-- Name: vacation_requests id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_requests ALTER COLUMN id SET DEFAULT nextval('public.vacation_requests_id_seq'::regclass);


--
-- Name: vacation_types id; Type: DEFAULT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_types ALTER COLUMN id SET DEFAULT nextval('public.vacation_types_id_seq'::regclass);


--
-- Data for Name: approval_level_members; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.approval_level_members (id, level_id, user_id) FROM stdin;
2	2	1
3	1	16
4	5	17
6	5	19
\.


--
-- Data for Name: approval_levels; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.approval_levels (id, name, description, step_order, created_at, updated_at, parent_id, is_rh) FROM stdin;
4	IT	\N	1	2026-05-06 13:13:31.620522+00	2026-05-06 21:02:18.783235+00	2	f
5	FE	\N	2	2026-05-06 19:09:19.512383+00	2026-05-06 21:02:18.787087+00	2	f
2	CTO	\N	2	2026-05-06 07:11:55.816467+00	2026-05-06 21:02:18.791175+00	1	f
1	RH	\N	1	2026-05-06 07:09:50.820367+00	2026-05-11 22:13:21.384459+00	\N	t
\.


--
-- Data for Name: approval_workflow_config; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.approval_workflow_config (id, step_order, role_name, required_permission, skip_after_hours, created_at) FROM stdin;
1	1	Gestor	VACATION:APPROVE	48	2026-05-04 16:59:08.120989+00
2	2	Administrador	VACATION:APPROVE	\N	2026-05-04 16:59:08.120989+00
\.


--
-- Data for Name: approval_workflow_steps; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.approval_workflow_steps (id, request_id, step_order, approver_id, role_name, status, comment, actioned_at, created_at, level_id) FROM stdin;
1	1	1	\N	RH	pending	\N	\N	2026-05-19 10:49:52.57042+00	1
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.audit_logs (id, user_id, user_name, action, entity_type, entity_id, entity_name, old_values, new_values, ip_address, user_agent, created_at) FROM stdin;
1	1	Administrador	CREATE	USER	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-16 20:21:43.654077
2	1	Administrador	UPDATE	USER_ROLE	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-16 20:21:43.67657
3	1	Administrador	UPDATE	USER	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-16 20:21:59.744971
4	1	Administrador	UPDATE	USER	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-24 19:11:48.202984
5	1	Administrador	UPDATE	USER	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-24 19:12:00.686412
6	1	Administrador	UPDATE	USER	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 00:27:10.729156
7	1	Administrador	UPDATE	USER_ROLE	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 00:27:10.756307
8	1	Administrador	CREATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:27:28.674847
9	1	Administrador	UPDATE	USER_ROLE	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:27:28.700172
10	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:54:56.436984
11	1	Administrador	UPDATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:29.797038
12	1	Administrador	UPDATE	USER_ROLE	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:29.819231
13	1	Administrador	UPDATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:31.26089
14	1	Administrador	UPDATE	USER_ROLE	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:31.279112
15	1	Administrador	UPDATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:32.348619
16	1	Administrador	UPDATE	USER_ROLE	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:32.377654
17	1	Administrador	UPDATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:34.997641
18	1	Administrador	UPDATE	USER_ROLE	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 01:55:35.010594
19	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 08:50:05.97982
20	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 08:55:33.670836
21	1	Administrador	UPDATE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:06:42.82797
22	1	Administrador	DELETE	USER	5	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:06:54.914405
23	1	Administrador	CREATE	USER	6	Kevintest Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:07:15.383244
24	1	Administrador	UPDATE	USER_ROLE	6	Kevintest Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:07:15.418257
25	1	Administrador	UPDATE	USER	6	Kevintest Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:13:04.338343
26	1	Administrador	DELETE	USER	6	Kevintest Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:13:11.923829
27	1	Administrador	CREATE	USER	7	Kevinsdds Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:13:22.47885
28	1	Administrador	UPDATE	USER_ROLE	7	Kevinsdds Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-25 09:13:22.501527
29	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:20:22.6691
30	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:30:53.705784
31	1	Administrador	CREATE	USER	8	dfs fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:40:06.454339
32	1	Administrador	UPDATE	USER_ROLE	8	dfs fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:40:06.487498
34	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:50:06.797973
35	1	Administrador	UPDATE	USER	7	Kevinsdds Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:50:16.283398
36	1	Administrador	CREATE	USER	10	bea bea	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:52:42.311971
37	1	Administrador	UPDATE	USER_ROLE	10	bea bea	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:52:42.342842
39	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:53:29.274693
40	1	Administrador	UPDATE	USER	8	dfs fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:53:51.144297
41	1	Administrador	UPDATE	USER	10	bea bea	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:53:53.27424
42	1	Administrador	DELETE	USER	7	Kevinsdds Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:05.411315
33	\N	dfs fds	LOGIN	SESSION	\N	fsd	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:40:36.825603
43	1	Administrador	DELETE	USER	8	dfs fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:08.19759
38	\N	bea bea	LOGIN	SESSION	\N	bea	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:53:25.448905
44	1	Administrador	DELETE	USER	10	bea bea	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:10.135174
45	1	Administrador	DELETE	USER	4	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:12.740079
46	1	Administrador	UPDATE	USER	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:26.935579
47	1	Administrador	UPDATE	USER_ROLE	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:55:26.95845
48	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 20:56:57.149204
49	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:00:29.587677
50	1	Administrador	UPDATE	USER	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:04:21.761293
51	1	Administrador	UPDATE	USER_ROLE	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:04:21.818844
52	1	Administrador	CREATE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:06:51.366946
53	1	Administrador	UPDATE	USER_ROLE	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:06:51.462471
54	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:07:53.918724
55	1	Administrador	UPDATE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:20.858062
56	1	Administrador	UPDATE	USER_ROLE	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:20.884471
57	1	Administrador	UPDATE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:25.788683
58	1	Administrador	UPDATE	USER_ROLE	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:25.811663
59	1	Administrador	UPDATE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:37.373171
60	1	Administrador	UPDATE	USER_ROLE	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:12:37.393147
61	1	Administrador	CREATE	USER	12	df@dfs.ds df@dfs.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:13:00.188437
62	1	Administrador	UPDATE	USER_ROLE	12	df@dfs.ds df@dfs.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:13:00.208929
63	1	Administrador	UPDATE	USER	12	df@dfs.ds df@dfs.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:13:08.139447
64	1	Administrador	UPDATE	USER	12	df@dfs.ds df@dfs.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:14:01.177661
65	1	Administrador	CREATE	USER	13	df@dfss.ds df@dfss.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:14:11.498342
66	1	Administrador	UPDATE	USER_ROLE	13	df@dfss.ds df@dfss.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:14:11.516875
67	1	Administrador	UPDATE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:14:37.307306
68	1	Administrador	CREATE	USER	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:22:57.372726
69	1	Administrador	UPDATE	USER_ROLE	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:22:57.411951
70	1	Administrador	UPDATE	USER	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:23:18.841294
71	1	Administrador	UPDATE	USER	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:23:23.33078
72	1	Administrador	UPDATE	USER	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:12.179938
73	1	Administrador	CREATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:19.5468
74	1	Administrador	UPDATE	USER_ROLE	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:19.575581
75	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:21.752791
76	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:27.557683
77	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:35.73089
78	1	Administrador	UPDATE	USER_ROLE	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:35.762546
79	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:40.474232
80	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:25:46.275766
81	1	Administrador	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:27:38.432995
82	1	Administrador	UPDATE	USER_ROLE	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-27 21:27:38.452298
83	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 06:29:43.922984
84	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 07:18:43.69328
85	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 07:35:11.057906
86	1	Administrador	CREATE	ROLE	5	tyrdst	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 07:37:04.755004
87	1	Administrador	UPDATE	USER_ROLE	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 07:37:04.819874
88	1	Administrador	UPDATE	ROLE	5	tyrdst	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 07:37:11.013054
89	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 21:12:06.568624
90	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 21:24:25.164482
91	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 21:31:12.229217
92	1	Administrador	UPDATE	ROLE	5	tyrdst	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 21:33:33.31267
93	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 21:55:55.954076
94	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 22:04:03.657509
95	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-28 22:08:17.573235
96	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-29 22:48:32.199617
97	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-29 23:51:06.502464
98	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-30 17:57:04.220414
99	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-04-30 18:44:40.524108
100	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-01 18:59:38.692336
101	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-01 20:00:48.881817
102	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 16:48:36.817708
103	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 17:49:09.541643
104	1	Administrador	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 21:53:49.994771
105	1	Administrador	CREATE	VACATION_REQUEST	1	Férias 2026-05-06 → 2026-05-06	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 21:58:38.963986
106	1	Administrador	UPDATE	USER	1	Administrador ..	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 22:12:53.747201
107	1	Administrador ..	UPDATE	USER_ROLE	1	Administrador ..	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-04 22:12:53.810224
108	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-05 08:25:21.517052
109	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-05 19:02:44.760001
110	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:09:37.179613
111	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 12:51:33.042971
112	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 13:12:37.386514
113	1	Administrador ..	CANCEL	VACATION_REQUEST	1	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 13:12:50.047578
114	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 18:44:21.958494
115	1	Administrador ..	CREATE	VACATION_REQUEST	2	Férias 2026-05-08 → 2026-05-10	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 18:45:31.398143
116	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 18:53:08.142179
117	1	Administrador ..	CREATE	USER	16	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 18:57:20.181046
118	1	Administrador ..	UPDATE	USER_ROLE	16	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 18:57:20.257765
119	1	Administrador ..	CREATE	VACATION_REQUEST	3	Férias 2026-05-15 → 2026-05-16	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:10:31.94532
120	1	Administrador ..	CREATE	USER	17	normal user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:17:28.923836
121	1	Administrador ..	UPDATE	USER_ROLE	17	normal user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:17:28.966802
122	1	Administrador ..	UPDATE	ROLE	5	Normal User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:19:54.536434
123	1	Administrador ..	UPDATE	USER	16	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:20:07.824294
124	1	Administrador ..	UPDATE	USER_ROLE	16	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:20:07.850199
125	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:20:57.648708
126	1	Administrador ..	UPDATE	ROLE	5	Normal User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:21:47.01335
127	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:22:00.036929
128	1	Administrador ..	CANCEL	VACATION_REQUEST	2	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:25:15.007975
129	16	RH User	CREATE	VACATION_REQUEST	4	Férias 2026-05-07 → 2026-05-07	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 19:35:03.274858
130	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 20:31:29.648859
131	16	RH User	CANCEL	VACATION_REQUEST	4	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 20:31:42.295931
132	16	RH User	CREATE	VACATION_REQUEST	5	Férias 2026-05-14 → 2026-05-14	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 20:31:51.05712
133	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 20:32:42.253062
134	17	normal user	LOGIN	SESSION	\N	normal.user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-06 21:01:00.23644
135	1	Administrador ..	UPDATE	USER	17	normal user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 21:04:05.080629
136	1	Administrador ..	UPDATE	USER_ROLE	17	normal user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 21:04:05.105955
137	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 21:23:46.499587
138	1	Administrador ..	UPDATE	USER	1	Administrador ..	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:17:50.280119
139	1	Administrador ..	UPDATE	USER_ROLE	1	Administrador ..	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:17:50.34402
140	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:25:53.83911
141	1	Administrador ..	CREATE	USER	18	test test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:30:43.90938
142	1	Administrador ..	UPDATE	USER_ROLE	18	test test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:30:43.967536
143	1	Administrador ..	CREATE	VACATION_REQUEST	6	Férias 2026-05-07 → 2026-05-09	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:47:10.107565
144	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:47:40.840886
145	16	RH User	APPROVE	VACATION_REQUEST	6	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 22:47:52.357417
146	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 10:34:42.437817
147	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 11:42:25.668737
148	1	Administrador ..	CREATE	VACATION_REQUEST	7	Férias 2026-05-12 → 2026-05-12	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 11:59:30.268796
149	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 12:10:24.062971
150	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 18:44:09.294638
151	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 20:41:29.177296
152	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 00:43:20.216752
153	1	Administrador ..	CREATE	VACATION_REQUEST	8	Férias 2026-05-10 → 2026-05-10	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:30:16.557781
154	1	Administrador ..	CREATE	VACATION_REQUEST	9	Férias 2026-05-11 → 2026-05-12	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:30:55.810386
155	1	Administrador ..	CREATE	VACATION_REQUEST	10	Férias 2026-05-09 → 2026-05-09	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:37:20.491305
156	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:44:13.2428
157	1	Administrador ..	CREATE	BLACKOUT_DATE	1	test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:48:01.973686
158	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 01:49:15.531798
159	1	Administrador ..	CREATE	VACATION_REQUEST	11	Férias 2026-05-09 → 2026-05-09	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 02:19:56.21322
160	1	Administrador ..	CREATE	VACATION_REQUEST	12	Férias 2026-05-13 → 2026-05-13	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 02:25:20.441132
161	1	Administrador ..	CREATE	VACATION_REQUEST	13	Férias 2026-05-20 → 2026-05-20	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 02:29:51.578884
162	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 02:47:32.585056
163	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 17:28:17.376426
164	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 19:37:38.746546
165	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 22:03:08.798188
166	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 22:36:59.429494
167	1	Administrador ..	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 22:56:29.447699
168	1	Administrador ..	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 22:56:37.486643
169	1	Administrador ..	UPDATE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 22:56:52.616248
170	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 14:45:24.034214
171	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 16:17:28.879459
172	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 21:32:28.632563
173	17	normal user	LOGIN	SESSION	\N	normal.user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 21:38:40.010247
174	17	normal user	LOGIN	SESSION	\N	normal.user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 21:52:10.79576
175	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 21:52:38.118582
176	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 21:52:57.905763
177	17	normal user	CREATE	VACATION_REQUEST	14	Férias 2026-05-11 → 2026-05-11	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 21:55:56.456643
178	1	Administrador ..	REJECT	VACATION_REQUEST	14	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 21:58:51.173616
179	17	normal user	CREATE	VACATION_REQUEST	15	Férias 2026-05-11 → 2026-05-11	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 21:59:28.740606
180	17	normal user	CREATE	VACATION_REQUEST	16	Férias 2026-05-11 → 2026-05-11	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 21:59:38.639073
181	17	normal user	CANCEL	VACATION_REQUEST	16	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 22:01:59.259327
182	1	Administrador ..	APPROVE	VACATION_REQUEST	15	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:03:17.142209
183	17	normal user	CREATE	VACATION_REQUEST	17	Férias 2026-05-14 → 2026-05-14	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 22:05:16.073404
184	1	Administrador ..	CREATE	USER	19	normal.user2 normal.user2	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:08:39.096321
185	1	Administrador ..	UPDATE	USER_ROLE	19	normal.user2 normal.user2	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:08:39.132651
186	1	Administrador ..	DELETE	BLACKOUT_DATE	1	test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:12:47.890962
187	1	Administrador ..	APPROVE	VACATION_REQUEST	17	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:12:54.007483
188	17	normal user	CREATE	VACATION_REQUEST	18	Férias 2026-05-15 → 2026-05-15	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 22:13:36.51874
189	1	Administrador ..	APPROVE	VACATION_REQUEST	18	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:14:34.357835
190	1	Administrador ..	CANCEL	VACATION_REQUEST	10	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:17:55.37963
191	1	Administrador ..	CANCEL	VACATION_REQUEST	9	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:17:58.153897
192	1	Administrador ..	CANCEL	VACATION_REQUEST	11	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:18:00.561251
193	1	Administrador ..	CANCEL	VACATION_REQUEST	7	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:18:02.936891
194	1	Administrador ..	CANCEL	VACATION_REQUEST	8	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:18:05.667133
195	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:28:42.307964
196	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 22:59:49.853883
197	19	normal.user2 normal.user2	CREATE	VACATION_REQUEST	19	Férias 2026-05-14 → 2026-05-15	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 23:04:34.460167
198	1	Administrador ..	UPDATE	ROLE	5	Normal User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 23:14:27.967139
199	19	normal.user2 normal.user2	LOGIN	SESSION	\N	normal.user2	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-11 23:14:38.389751
200	1	Administrador ..	UPDATE	ROLE	5	Normal User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 23:15:10.072509
201	1	Administrador ..	APPROVE	VACATION_REQUEST	19	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-11 23:27:29.015641
202	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 19:49:57.113868
203	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 19:50:45.356928
204	17	normal user	LOGIN	SESSION	\N	normal.user	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-12 19:52:23.172868
205	19	normal.user2 normal.user2	LOGIN	SESSION	\N	normal.user2	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-12 19:52:30.462158
206	19	normal.user2 normal.user2	CREATE	VACATION_REQUEST	20	Férias 2026-05-16 → 2026-05-16	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-12 20:04:41.046668
207	1	Administrador ..	APPROVE	VACATION_REQUEST	20	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:08:00.580252
208	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:09:58.060561
209	1	Administrador ..	CREATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:11:27.927935
210	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:11:42.170357
211	1	Administrador ..	UPDATE	USER_ROLE	16	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:11:42.368855
212	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:12:20.681073
213	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:13:28.45188
214	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:14:58.260048
215	1	Administrador ..	APPROVE	VACATION_REQUEST	20	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:26:55.487552
216	19	normal.user2 normal.user2	CREATE	VACATION_REQUEST	21	Férias 2026-05-22 → 2026-05-22	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-12 20:38:16.258294
217	1	Administrador ..	APPROVE	VACATION_REQUEST	21	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 20:38:44.63051
218	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 21:00:42.237147
219	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 21:46:04.679672
220	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 21:46:28.237944
221	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 21:46:52.644783
222	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 22:31:47.271118
223	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 22:33:56.726814
224	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 22:34:22.183836
225	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 22:34:28.554909
226	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 18:46:40.614167
227	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:35:43.717983
228	1	Administrador ..	UPDATE	ROLE	6	RH User	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:35:51.180006
229	16	RH User	LOGIN	SESSION	\N	rhadmin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:36:02.678368
230	1	Administrador ..	UPDATE	USER	18	test test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:42:54.188691
231	1	Administrador ..	UPDATE	USER	3	João Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:00.10098
232	1	Administrador ..	UPDATE	USER	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:03.475454
233	1	Administrador ..	DELETE	USER	3	João Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:35.60785
234	1	Administrador ..	DELETE	USER	12	df@dfs.ds df@dfs.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:38.182279
235	1	Administrador ..	DELETE	USER	13	df@dfss.ds df@dfss.ds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:40.827515
236	1	Administrador ..	DELETE	USER	14	dsaads@dfs.fdsv dsaads@dfs.fdsv	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:43.343526
237	1	Administrador ..	DELETE	USER	15	dsaads@dfs.fdsvs dsaads@dfs.fdsvs	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:45.5153
238	1	Administrador ..	DELETE	USER	11	fds fds	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:47.464221
239	1	Administrador ..	DELETE	USER	2	Gestor sil	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:49.571905
240	1	Administrador ..	DELETE	USER	18	test test	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:43:52.335552
241	1	Administrador ..	CREATE	USER	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:53:42.885067
242	1	Administrador ..	UPDATE	USER_ROLE	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:53:42.946503
243	1	Administrador ..	UPDATE	USER	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:54:09.778697
244	1	Administrador ..	UPDATE	USER_ROLE	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:54:09.800489
245	1	Administrador ..	UPDATE	USER	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:54:41.433577
246	1	Administrador ..	UPDATE	USER_ROLE	20	Kevin Silva	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-13 20:54:41.454325
247	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 21:01:11.486099
248	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:31:49.119787
249	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:49:26.903656
250	1	Administrador ..	CREATE	VACATION_REQUEST	1	Férias 2026-05-28 → 2026-06-06	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:49:52.593309
251	1	Administrador ..	CANCEL	VACATION_REQUEST	1	\N	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:49:57.503158
252	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 16:31:20.898365
253	1	Administrador ..	LOGIN	SESSION	\N	admin	\N	\N	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-31 17:28:00.384178
\.


--
-- Data for Name: blackout_dates; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.blackout_dates (id, title, start_date, end_date, reason, department, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: config_variables; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.config_variables (id, section, key, label, value, is_secret, description, input_type, created_at, updated_at) FROM stdin;
8	rooms	slot_duration	Duração mínima de reserva (minutos)	30	f	Intervalo de tempo para seleção de horários. Ex: 30 = blocos de 30 em 30 minutos	number	2026-04-28 07:21:57.604181+00	2026-04-28 22:04:50.774694+00
9	rooms	booking_start	Hora de abertura	08:00	f	Hora mais cedo disponível para reservas	text	2026-04-28 07:21:57.604181+00	2026-04-28 22:04:50.777393+00
10	rooms	booking_end	Hora de encerramento	23:30	f	Hora mais tarde disponível para reservas	text	2026-04-28 07:21:57.604181+00	2026-04-28 22:04:50.779528+00
11	rooms	outlook_default_body	Corpo padrão (Outlook)	Reunião agendada através do sistema de salas de reunião.	f	Texto padrão para o email do Outlook quando a reserva não tem descrição	text	2026-04-29 23:55:25.599325+00	2026-04-29 23:55:25.599325+00
34	ferias	vacation_birthday_enabled	Ativar folga de aniversário	true	f	Permite aos utilizadores solicitar o dia de aniversário como dia de folga adicional	checkbox	2026-05-04 22:08:52.126542+00	2026-05-06 22:30:09.520406+00
12	msgraph	msgraph_enabled	Integração Ativa	true	f	Activar sincronização bidirecional com Microsoft 365	checkbox	2026-05-01 20:26:59.038779+00	2026-05-12 22:48:17.198382+00
13	msgraph	msgraph_tenant_id	Tenant ID (Azure AD)	admin	f	ID do tenant do Azure Active Directory (Directory ID)	text	2026-05-01 20:26:59.038779+00	2026-05-12 22:48:17.207133+00
14	msgraph	msgraph_client_id	Client ID (App ID)		f	ID da aplicação registada no Azure AD (Application ID)	text	2026-05-01 20:26:59.038779+00	2026-05-12 22:48:17.211997+00
15	msgraph	msgraph_client_secret	Client Secret	admin123	t	Segredo da aplicação — gerar em Azure AD → Certificates & secrets	password	2026-05-01 20:26:59.038779+00	2026-05-12 22:48:17.215447+00
16	msgraph	msgraph_webhook_secret	Webhook clientState		f	Valor secreto para validar notificações recebidas do Graph	text	2026-05-01 20:26:59.038779+00	2026-05-12 22:48:17.218849+00
1	email	smtp_host	SMTP Host	smtp.gmail.com	f	Endereço do servidor SMTP (ex: smtp.gmail.com)	text	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.400478+00
2	email	smtp_port	SMTP Port	587	f	Porta SMTP (25, 465, 587)	number	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.406389+00
3	email	smtp_secure	Usar SSL/TLS	false	f	Activar conexão segura SSL/TLS (porta 465)	checkbox	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.408383+00
4	email	smtp_user	Utilizador SMTP	kevinsilvakck1998@gmail.com	f	Email ou utilizador de autenticação	text	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.410185+00
5	email	smtp_password	Password SMTP	zlcy avpr wsoq jswy	t	Password de autenticação SMTP	password	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.411838+00
6	email	from_email	Email de Origem	kevinsilvakck1998@gmail.com	f	Endereço de email do remetente	email	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.413042+00
7	email	from_name	Nome de Origem	Sistema SIGI	f	Nome que aparece como remetente	text	2026-04-25 01:25:11.531816+00	2026-05-13 21:15:07.414391+00
\.


--
-- Data for Name: leave_balances; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.leave_balances (id, employee_id, year, base_days, seniority_bonus, birthday_bonus, used_days, pending_days, updated_at, carryover_days) FROM stdin;
1	1	2026	22	0	0	0.0	0.0	2026-05-19 16:36:39.672484+00	0.0
\.


--
-- Data for Name: meeting_rooms; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.meeting_rooms (id, name, description, image_url, capacity, location, amenities, status, created_at, updated_at) FROM stdin;
2	Sala 3	Sala pequena e confortável para pequenas equipas		4	Piso 2	TV 43"	active	2026-04-27 22:14:16.686825+00	2026-05-06 20:53:35.888+00
1	Sala 1	Sala principal com quadro branco e sofá		10	Piso 1	TV 65", Quadro Branco, Sofá	active	2026-04-27 22:14:16.686825+00	2026-05-06 20:54:29.063+00
4	Sala 2	Sala de corredor com TV		8		TV 43"	active	2026-05-06 20:54:35.736889+00	2026-05-06 20:55:06.074+00
\.


--
-- Data for Name: msgraph_subscriptions; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.msgraph_subscriptions (id, subscription_id, room_id, resource_email, expiration_datetime, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.password_reset_tokens (id, user_id, token, expires_at, used_at, created_at) FROM stdin;
10	16	2d94c5ab6b0825fdc6c0404617f25cb43a2b5bd6b89c649ce40023405199bfd5	2026-05-13 18:57:20.185+00	2026-05-06 18:58:35.422814+00	2026-05-06 18:57:20.184339+00
11	17	b438d8898351f9225c4484ec74d08e1876d7140d22eca1ce65e74b3a05e7541e	2026-05-13 19:17:28.926+00	2026-05-06 19:17:56.330578+00	2026-05-06 19:17:28.928676+00
15	19	4cf1a50abbf9c530b221beacf4a6d1b9abc6d2e4f43f712d7a93ec8b76ede248	2026-05-18 22:08:39.102+00	2026-05-11 22:09:36.152935+00	2026-05-11 22:08:39.100363+00
27	20	881bfe7bbf1f7aad905ac1631850739f598bc79c05ce9e83f4b0ad6e4a9f7811	2026-05-20 21:15:35.356+00	\N	2026-05-13 21:15:35.353989+00
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.permissions (id, code, description, module, action, created_at) FROM stdin;
1	VACATION:VIEW_OWN	Ver apenas as minhas férias	VACATION	VIEW_OWN	2026-04-16 19:29:47.924652
2	VACATION:VIEW_TEAM	Ver férias da equipa	VACATION	VIEW_TEAM	2026-04-16 19:29:47.924652
3	VACATION:CREATE	Criar pedido de férias	VACATION	CREATE	2026-04-16 19:29:47.924652
5	VACATION:CONFIG_PERIODS	Configurar períodos globais de férias	VACATION	CONFIG_PERIODS	2026-04-16 19:29:47.924652
11	ROOMS:VIEW	Ver salas de reunião disponíveis	ROOMS	VIEW	2026-04-16 19:29:47.924652
12	ROOMS:RESERVE	Fazer reserva de sala	ROOMS	RESERVE	2026-04-16 19:29:47.924652
13	ROOMS:CANCEL_OWN	Cancelar própria reserva	ROOMS	CANCEL_OWN	2026-04-16 19:29:47.924652
14	ROOMS:CANCEL_ANY	Cancelar qualquer reserva	ROOMS	CANCEL_ANY	2026-04-16 19:29:47.924652
15	ROOMS:MANAGE	Gerir salas e disponibilidade	ROOMS	MANAGE	2026-04-16 19:29:47.924652
16	SETTINGS:VIEW	Ver definições do sistema	SETTINGS	VIEW	2026-04-16 19:29:47.924652
17	SETTINGS:CHANGE	Alterar definições do sistema	SETTINGS	CHANGE	2026-04-16 19:29:47.924652
18	SETTINGS:MANAGE_USERS	Gerir utilizadores	SETTINGS	MANAGE_USERS	2026-04-16 19:29:47.924652
19	SETTINGS:MANAGE_ROLES	Gerir roles e permissões	SETTINGS	MANAGE_ROLES	2026-04-16 19:29:47.924652
20	VACATION:VIEW_LEVELS	Ver Níveis de Aprovação	VACATION	VIEW_LEVELS	2026-05-06 22:10:01.59984
22	VACATION:IMPORT_BALANCES	Importar Saldos de Férias	VACATION	IMPORT_BALANCES	2026-05-09 01:17:59.624168
23	VACATION:VIEW_ALL_TEAM	Ver toda a equipa	VACATION	VIEW_ALL_TEAM	2026-05-09 02:00:05.841861
24	VACATION:EXPORT_REPORTS	Exportar Relatórios de Férias	VACATION	EXPORT_REPORTS	2026-05-10 22:19:26.475344
25	VACATION:APPROVE	Aprovar pedidos de férias	VACATION	APPROVE	2026-05-12 19:58:47.4302
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.positions (id, name, description, parent_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.role_permissions (role_id, permission_id) FROM stdin;
1	1
1	2
1	3
1	5
1	11
1	12
1	13
1	14
1	15
1	16
1	17
1	18
1	19
2	1
2	2
2	3
2	5
2	11
2	12
2	13
2	14
2	15
2	16
6	12
6	25
6	5
6	3
6	24
6	22
6	23
6	1
6	11
3	1
3	2
3	3
3	11
3	12
2	20
2	25
1	20
1	22
1	23
1	24
1	25
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.roles (id, name, description, is_system, created_at, updated_at) FROM stdin;
1	Admin	Administrador com acesso total ao sistema	t	2026-04-16 19:29:47.921615	2026-04-16 19:29:47.921615
3	Funcionário	Colaborador padrão	t	2026-04-16 19:29:47.921615	2026-04-16 19:29:47.921615
2	Gestor	Gestor de equipa com permissões alargadas	t	2026-04-16 19:29:47.921615	2026-04-16 19:29:47.921615
6	RH		t	2026-05-12 20:11:27.922362	2026-05-13 20:35:51.174
\.


--
-- Data for Name: room_graph_mappings; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.room_graph_mappings (id, room_id, resource_email, created_at) FROM stdin;
\.


--
-- Data for Name: room_reservations; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.room_reservations (id, room_id, user_id, guest_name, booking_token, token_expires_at, meeting_title, start_time, end_time, created_at, description, ical_uid, change_key, graph_event_id, source) FROM stdin;
6	1	1	\N	\N	\N	test	2026-05-08 08:00:00+00	2026-05-08 09:00:00+00	2026-04-30 17:57:32.037827+00	\N	\N	\N	\N	platform
8	1	1	\N	\N	\N	test123	2026-05-01 21:30:00+00	2026-05-01 22:00:00+00	2026-05-01 20:33:49.947288+00	test123	\N	\N	\N	platform
9	1	1	\N	\N	\N	tA1	2026-05-01 22:00:00+00	2026-05-01 22:30:00+00	2026-05-01 20:34:11.711992+00	tA1	\N	\N	\N	platform
10	1	1	\N	\N	\N	test1	2026-05-01 21:00:00+00	2026-05-01 21:30:00+00	2026-05-01 20:39:09.444322+00	test1	\N	\N	\N	platform
11	1	1	\N	\N	\N	hggh	2026-05-05 09:00:00+00	2026-05-05 10:30:00+00	2026-05-05 08:26:16.872369+00	hgf	\N	\N	\N	platform
13	1	1	\N	\N	\N	titulo	2026-05-11 17:00:00+00	2026-05-11 17:30:00+00	2026-05-11 16:17:47.991483+00	\N	\N	\N	\N	platform
14	1	16	\N	\N	\N	yrdy	2026-05-13 21:30:00+00	2026-05-13 22:00:00+00	2026-05-13 20:36:13.77589+00	yrdy	\N	\N	\N	platform
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.user_roles (id, user_id, role_id, assigned_at, assigned_by) FROM stdin;
35	1	1	2026-05-06 22:17:50.336786	1
39	16	6	2026-05-12 20:11:42.362276	1
34	17	3	2026-05-06 21:04:05.099074	1
37	19	3	2026-05-11 22:08:39.123937	1
38	16	3	2026-05-12 20:11:42.358542	1
42	20	3	2026-05-13 20:54:41.449967	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.users (id, username, password, name, email, department, role_id, permission, status, created_at, updated_at, must_change_password, job_title, hire_date, birthday, position_id, employee_no) FROM stdin;
1	admin	$2b$10$xn/YpyF2OAwALd8gicGoCOcMcV5Q5ZSnyV9tD9nbXMRjU9O48uKVS	Administrador ..	admin@solverdept.pt	IT	1	0	1	2026-04-16 19:29:47.932489	2026-05-06 22:17:50.272	f	\N	2024-05-20	2026-05-20	\N	01319
17	normal.user	$2b$10$oqqTMrm/Cn7NwupDw8GpiOHF9kXqOl2sGX8C1ymabEQgQQc9GwhZO	normal user	normal@solverde.pt	\N	\N	3	1	2026-05-06 19:17:28.915671	2026-05-06 21:04:05.071	f	\N	\N	\N	\N	\N
19	normal.user2	$2b$10$QcqIdcqxhoLpq6pD6KOJsu86fyrBFZ4ngCpx2KQUbudyEvAUJOYim	normal.user2 normal.user2	normal.user2@solverde.pt	\N	\N	3	1	2026-05-11 22:08:39.090735	2026-05-11 22:09:36.147965	f	\N	\N	\N	\N	23dws
16	rhadmin	$2b$10$kzuSY7tqgDYpAnjAljCs1.LPJdqcJgozQKOvdv1OxFPfGh3O/FBMu	RH User	rh@solverde.pt	\N	\N	3	1	2026-05-06 18:57:20.174586	2026-05-06 19:20:07.816	f	\N	\N	\N	\N	\N
20	kevin.silva	\N	Kevin Silva	kevingamerkps@gmail.com	\N	3	3	2	2026-05-13 20:53:42.877572	2026-05-13 20:54:41.437	f	\N	\N	\N	\N	PO02
\.


--
-- Data for Name: vacation_request_history; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.vacation_request_history (id, request_id, actor_id, actor_name, old_status, new_status, step_order, comment, actioned_at) FROM stdin;
1	1	1	Administrador ..	\N	pending	0	Pedido submetido	2026-05-19 10:49:52.5956+00
2	1	1	Administrador ..	pending	cancelled	\N	Pedido cancelado	2026-05-19 10:49:57.500597+00
\.


--
-- Data for Name: vacation_requests; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.vacation_requests (id, employee_id, type, start_date, end_date, days_count, reason, status, current_approval_step, created_at, updated_at, half_day, processed_externally) FROM stdin;
1	1	annual	2026-05-28	2026-06-06	7.0	\N	cancelled	1	2026-05-19 10:49:52.55245+00	2026-05-19 10:49:57.487958+00	f	f
\.


--
-- Data for Name: vacation_types; Type: TABLE DATA; Schema: public; Owner: azidav
--

COPY public.vacation_types (id, name, code, uses_balance, requires_approval_chain, is_active, sort_order, created_at, updated_at) FROM stdin;
1	Dias Férias	annual	t	t	t	1	2026-05-09 02:15:02.458712+00	2026-05-12 22:26:21.101192+00
2	DF Justificada S/R	outro_justificada	f	f	t	2	2026-05-09 02:19:38.425639+00	2026-05-12 22:27:12.82458+00
3	DF Falta Injustificada S/Rem	df_falta_injustificada_s_rem	f	f	t	3	2026-05-12 22:27:25.956011+00	2026-05-12 22:27:25.956011+00
8	DF Baixa Seguro S/Rem	df_baixa_seguro_s_rem	f	f	t	8	2026-05-12 22:28:04.172314+00	2026-05-12 22:28:04.172314+00
9	DF Licença Parental S/Rem	df_licenca_parental_s_rem	f	f	t	9	2026-05-12 22:28:11.017202+00	2026-05-12 22:28:11.017202+00
10	DF Justificada c/R - Eleições	df_justificada_c_r_eleicoes	f	f	t	10	2026-05-12 22:28:17.066768+00	2026-05-12 22:28:17.066768+00
11	HF Consulta/Exames Pré-Natal C/R	hf_consulta_exames_pre_natal_c_r	f	f	t	11	2026-05-12 22:28:23.595884+00	2026-05-12 22:28:23.595884+00
12	HF Amamentação/ Aleitação	hf_amamentacao_aleitacao	f	f	t	12	2026-05-12 22:28:29.269961+00	2026-05-12 22:28:29.269961+00
13	HF Frequência de Aulas C/R	hf_frequencia_de_aulas_c_r	f	f	t	13	2026-05-12 22:28:35.329159+00	2026-05-12 22:28:35.329159+00
14	HF Provas de Avaliação C/R	hf_provas_de_avaliacao_c_r	f	f	t	14	2026-05-12 22:28:40.811987+00	2026-05-12 22:28:40.811987+00
4	DF Licença de Casamento C/R	df_licenca_de_casamento_c_r	f	f	t	4	2026-05-12 22:27:30.647971+00	2026-05-12 22:28:45.494421+00
5	DF Luto	df_luto	f	f	t	5	2026-05-12 22:27:41.290637+00	2026-05-12 22:28:49.843448+00
6	DF Aniversário c/R	df_aniversario_c_r	f	f	t	6	2026-05-12 22:27:51.355662+00	2026-05-12 22:28:54.117096+00
7	DF Baixa Seg. Social N/Rem	df_baixa_seg_social_n_rem	f	f	t	7	2026-05-12 22:27:56.826013+00	2026-05-12 22:28:59.290289+00
\.


--
-- Name: approval_level_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.approval_level_members_id_seq', 6, true);


--
-- Name: approval_levels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.approval_levels_id_seq', 5, true);


--
-- Name: approval_workflow_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.approval_workflow_config_id_seq', 4, true);


--
-- Name: approval_workflow_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.approval_workflow_steps_id_seq', 1, true);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 253, true);


--
-- Name: blackout_dates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.blackout_dates_id_seq', 1, true);


--
-- Name: config_variables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.config_variables_id_seq', 52, true);


--
-- Name: leave_balances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.leave_balances_id_seq', 12, true);


--
-- Name: meeting_rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.meeting_rooms_id_seq', 4, true);


--
-- Name: msgraph_subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.msgraph_subscriptions_id_seq', 1, false);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.password_reset_tokens_id_seq', 27, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.permissions_id_seq', 25, true);


--
-- Name: positions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.positions_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.roles_id_seq', 6, true);


--
-- Name: room_graph_mappings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.room_graph_mappings_id_seq', 6, true);


--
-- Name: room_reservations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.room_reservations_id_seq', 14, true);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.user_roles_id_seq', 42, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.users_id_seq', 20, true);


--
-- Name: vacation_request_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.vacation_request_history_id_seq', 2, true);


--
-- Name: vacation_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.vacation_requests_id_seq', 1, true);


--
-- Name: vacation_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: azidav
--

SELECT pg_catalog.setval('public.vacation_types_id_seq', 14, true);


--
-- Name: approval_level_members approval_level_members_level_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_level_id_user_id_key UNIQUE (level_id, user_id);


--
-- Name: approval_level_members approval_level_members_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_pkey PRIMARY KEY (id);


--
-- Name: approval_levels approval_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_levels
    ADD CONSTRAINT approval_levels_pkey PRIMARY KEY (id);


--
-- Name: approval_workflow_config approval_workflow_config_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_config
    ADD CONSTRAINT approval_workflow_config_pkey PRIMARY KEY (id);


--
-- Name: approval_workflow_config approval_workflow_config_step_order_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_config
    ADD CONSTRAINT approval_workflow_config_step_order_key UNIQUE (step_order);


--
-- Name: approval_workflow_steps approval_workflow_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: blackout_dates blackout_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT blackout_dates_pkey PRIMARY KEY (id);


--
-- Name: config_variables config_variables_key_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.config_variables
    ADD CONSTRAINT config_variables_key_key UNIQUE (key);


--
-- Name: config_variables config_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.config_variables
    ADD CONSTRAINT config_variables_pkey PRIMARY KEY (id);


--
-- Name: leave_balances leave_balances_employee_id_year_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_year_key UNIQUE (employee_id, year);


--
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id);


--
-- Name: meeting_rooms meeting_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.meeting_rooms
    ADD CONSTRAINT meeting_rooms_pkey PRIMARY KEY (id);


--
-- Name: msgraph_subscriptions msgraph_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: msgraph_subscriptions msgraph_subscriptions_subscription_id_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_subscription_id_key UNIQUE (subscription_id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_token_key UNIQUE (token);


--
-- Name: permissions permissions_code_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_code_key UNIQUE (code);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: room_graph_mappings room_graph_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_pkey PRIMARY KEY (id);


--
-- Name: room_graph_mappings room_graph_mappings_resource_email_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_resource_email_key UNIQUE (resource_email);


--
-- Name: room_reservations room_reservations_booking_token_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_booking_token_key UNIQUE (booking_token);


--
-- Name: room_reservations room_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vacation_request_history vacation_request_history_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_pkey PRIMARY KEY (id);


--
-- Name: vacation_requests vacation_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_requests
    ADD CONSTRAINT vacation_requests_pkey PRIMARY KEY (id);


--
-- Name: vacation_types vacation_types_code_key; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_types
    ADD CONSTRAINT vacation_types_code_key UNIQUE (code);


--
-- Name: vacation_types vacation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_types
    ADD CONSTRAINT vacation_types_pkey PRIMARY KEY (id);


--
-- Name: idx_approval_level_members_level_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_approval_level_members_level_id ON public.approval_level_members USING btree (level_id);


--
-- Name: idx_approval_level_members_user_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_approval_level_members_user_id ON public.approval_level_members USING btree (user_id);


--
-- Name: idx_approval_levels_step_order; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_approval_levels_step_order ON public.approval_levels USING btree (step_order);


--
-- Name: idx_approval_steps_request_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_approval_steps_request_id ON public.approval_workflow_steps USING btree (request_id);


--
-- Name: idx_approval_steps_status; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_approval_steps_status ON public.approval_workflow_steps USING btree (status);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_entity_type; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_blackout_dates_end_date; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_blackout_dates_end_date ON public.blackout_dates USING btree (end_date);


--
-- Name: idx_blackout_dates_start_date; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_blackout_dates_start_date ON public.blackout_dates USING btree (start_date);


--
-- Name: idx_meeting_rooms_status; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_meeting_rooms_status ON public.meeting_rooms USING btree (status);


--
-- Name: idx_permissions_code; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_permissions_code ON public.permissions USING btree (code);


--
-- Name: idx_permissions_module; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_permissions_module ON public.permissions USING btree (module);


--
-- Name: idx_positions_parent_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_positions_parent_id ON public.positions USING btree (parent_id);


--
-- Name: idx_reset_tokens_token; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_reset_tokens_token ON public.password_reset_tokens USING btree (token);


--
-- Name: idx_roles_name; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_roles_name ON public.roles USING btree (name);


--
-- Name: idx_room_reservations_ical_uid; Type: INDEX; Schema: public; Owner: azidav
--

CREATE UNIQUE INDEX idx_room_reservations_ical_uid ON public.room_reservations USING btree (ical_uid) WHERE (ical_uid IS NOT NULL);


--
-- Name: idx_room_reservations_room_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_room_reservations_room_id ON public.room_reservations USING btree (room_id);


--
-- Name: idx_room_reservations_start_time; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_room_reservations_start_time ON public.room_reservations USING btree (start_time);


--
-- Name: idx_room_reservations_token; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_room_reservations_token ON public.room_reservations USING btree (booking_token);


--
-- Name: idx_room_reservations_user_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_room_reservations_user_id ON public.room_reservations USING btree (user_id);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_employee_no; Type: INDEX; Schema: public; Owner: azidav
--

CREATE UNIQUE INDEX idx_users_employee_no ON public.users USING btree (employee_no) WHERE (employee_no IS NOT NULL);


--
-- Name: idx_users_permission; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_users_permission ON public.users USING btree (permission);


--
-- Name: idx_users_role_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: idx_vacation_request_history_request_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_vacation_request_history_request_id ON public.vacation_request_history USING btree (request_id);


--
-- Name: idx_vacation_requests_employee_id; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_vacation_requests_employee_id ON public.vacation_requests USING btree (employee_id);


--
-- Name: idx_vacation_requests_start_date; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_vacation_requests_start_date ON public.vacation_requests USING btree (start_date);


--
-- Name: idx_vacation_requests_status; Type: INDEX; Schema: public; Owner: azidav
--

CREATE INDEX idx_vacation_requests_status ON public.vacation_requests USING btree (status);


--
-- Name: approval_level_members approval_level_members_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.approval_levels(id) ON DELETE CASCADE;


--
-- Name: approval_level_members approval_level_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: approval_levels approval_levels_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_levels
    ADD CONSTRAINT approval_levels_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.approval_levels(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.approval_levels(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.vacation_requests(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: blackout_dates blackout_dates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT blackout_dates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: leave_balances leave_balances_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: msgraph_subscriptions msgraph_subscriptions_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE SET NULL;


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: positions positions_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.positions(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: room_graph_mappings room_graph_mappings_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE CASCADE;


--
-- Name: room_reservations room_reservations_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE CASCADE;


--
-- Name: room_reservations room_reservations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id) ON DELETE SET NULL;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE SET NULL;


--
-- Name: vacation_request_history vacation_request_history_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: vacation_request_history vacation_request_history_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.vacation_requests(id) ON DELETE CASCADE;


--
-- Name: vacation_requests vacation_requests_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: azidav
--

ALTER TABLE ONLY public.vacation_requests
    ADD CONSTRAINT vacation_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict d2lYggnPZbEaOj0C6ZnCGcp3gjbLWePHOmJnaEJ7KJLvaT39HCFIbkQcLroGcFh

