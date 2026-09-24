--
-- PostgreSQL database dump
--

\restrict 8MUQK21Mso0c6XdLgi0M2PQuN2N4IYww0T1L2kDm0GYH7NhuAhNhEKlZHXQqak3

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
-- Name: approval_level_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.approval_level_members (
    id integer NOT NULL,
    level_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: approval_level_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.approval_level_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: approval_level_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.approval_level_members_id_seq OWNED BY public.approval_level_members.id;


--
-- Name: approval_levels; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: approval_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.approval_levels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: approval_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.approval_levels_id_seq OWNED BY public.approval_levels.id;


--
-- Name: approval_workflow_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.approval_workflow_config (
    id integer NOT NULL,
    step_order integer NOT NULL,
    role_name character varying(100) NOT NULL,
    required_permission character varying(100) DEFAULT 'VACATION:APPROVE'::character varying NOT NULL,
    skip_after_hours integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: approval_workflow_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.approval_workflow_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: approval_workflow_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.approval_workflow_config_id_seq OWNED BY public.approval_workflow_config.id;


--
-- Name: approval_workflow_steps; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: approval_workflow_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.approval_workflow_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: approval_workflow_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.approval_workflow_steps_id_seq OWNED BY public.approval_workflow_steps.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: blackout_dates; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: blackout_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blackout_dates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blackout_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blackout_dates_id_seq OWNED BY public.blackout_dates.id;


--
-- Name: config_variables; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: config_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.config_variables_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.config_variables_id_seq OWNED BY public.config_variables.id;


--
-- Name: leave_balances; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: leave_balances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.leave_balances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leave_balances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.leave_balances_id_seq OWNED BY public.leave_balances.id;


--
-- Name: meeting_rooms; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: meeting_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.meeting_rooms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.meeting_rooms_id_seq OWNED BY public.meeting_rooms.id;


--
-- Name: msgraph_subscriptions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: msgraph_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.msgraph_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: msgraph_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.msgraph_subscriptions_id_seq OWNED BY public.msgraph_subscriptions.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id integer NOT NULL,
    user_id integer NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.password_reset_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_reset_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.password_reset_tokens_id_seq OWNED BY public.password_reset_tokens.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    code character varying(100) NOT NULL,
    description text NOT NULL,
    module character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    id integer NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    parent_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.positions_id_seq OWNED BY public.positions.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_system boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: room_graph_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_graph_mappings (
    id integer NOT NULL,
    room_id integer NOT NULL,
    resource_email character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: room_graph_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.room_graph_mappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_graph_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.room_graph_mappings_id_seq OWNED BY public.room_graph_mappings.id;


--
-- Name: room_reservations; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: room_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.room_reservations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.room_reservations_id_seq OWNED BY public.room_reservations.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    assigned_at timestamp without time zone DEFAULT now(),
    assigned_by integer
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vacation_request_history; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: vacation_request_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vacation_request_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vacation_request_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vacation_request_history_id_seq OWNED BY public.vacation_request_history.id;


--
-- Name: vacation_requests; Type: TABLE; Schema: public; Owner: -
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
    processed_externally boolean DEFAULT false NOT NULL,
    half_day_period character varying(10),
    CONSTRAINT chk_vacation_requests_half_day_period CHECK (((half_day_period)::text = ANY ((ARRAY['morning'::character varying, 'afternoon'::character varying])::text[])))
);


--
-- Name: vacation_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vacation_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vacation_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vacation_requests_id_seq OWNED BY public.vacation_requests.id;


--
-- Name: vacation_types; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: vacation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vacation_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vacation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vacation_types_id_seq OWNED BY public.vacation_types.id;


--
-- Name: approval_level_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_level_members ALTER COLUMN id SET DEFAULT nextval('public.approval_level_members_id_seq'::regclass);


--
-- Name: approval_levels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_levels ALTER COLUMN id SET DEFAULT nextval('public.approval_levels_id_seq'::regclass);


--
-- Name: approval_workflow_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_config ALTER COLUMN id SET DEFAULT nextval('public.approval_workflow_config_id_seq'::regclass);


--
-- Name: approval_workflow_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_steps ALTER COLUMN id SET DEFAULT nextval('public.approval_workflow_steps_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: blackout_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates ALTER COLUMN id SET DEFAULT nextval('public.blackout_dates_id_seq'::regclass);


--
-- Name: config_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_variables ALTER COLUMN id SET DEFAULT nextval('public.config_variables_id_seq'::regclass);


--
-- Name: leave_balances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances ALTER COLUMN id SET DEFAULT nextval('public.leave_balances_id_seq'::regclass);


--
-- Name: meeting_rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meeting_rooms ALTER COLUMN id SET DEFAULT nextval('public.meeting_rooms_id_seq'::regclass);


--
-- Name: msgraph_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msgraph_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.msgraph_subscriptions_id_seq'::regclass);


--
-- Name: password_reset_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens ALTER COLUMN id SET DEFAULT nextval('public.password_reset_tokens_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ALTER COLUMN id SET DEFAULT nextval('public.positions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: room_graph_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_graph_mappings ALTER COLUMN id SET DEFAULT nextval('public.room_graph_mappings_id_seq'::regclass);


--
-- Name: room_reservations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_reservations ALTER COLUMN id SET DEFAULT nextval('public.room_reservations_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vacation_request_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_request_history ALTER COLUMN id SET DEFAULT nextval('public.vacation_request_history_id_seq'::regclass);


--
-- Name: vacation_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_requests ALTER COLUMN id SET DEFAULT nextval('public.vacation_requests_id_seq'::regclass);


--
-- Name: vacation_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_types ALTER COLUMN id SET DEFAULT nextval('public.vacation_types_id_seq'::regclass);


--
-- Name: approval_level_members approval_level_members_level_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_level_id_user_id_key UNIQUE (level_id, user_id);


--
-- Name: approval_level_members approval_level_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_pkey PRIMARY KEY (id);


--
-- Name: approval_levels approval_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_levels
    ADD CONSTRAINT approval_levels_pkey PRIMARY KEY (id);


--
-- Name: approval_workflow_config approval_workflow_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_config
    ADD CONSTRAINT approval_workflow_config_pkey PRIMARY KEY (id);


--
-- Name: approval_workflow_config approval_workflow_config_step_order_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_config
    ADD CONSTRAINT approval_workflow_config_step_order_key UNIQUE (step_order);


--
-- Name: approval_workflow_steps approval_workflow_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: blackout_dates blackout_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT blackout_dates_pkey PRIMARY KEY (id);


--
-- Name: config_variables config_variables_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_variables
    ADD CONSTRAINT config_variables_key_key UNIQUE (key);


--
-- Name: config_variables config_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.config_variables
    ADD CONSTRAINT config_variables_pkey PRIMARY KEY (id);


--
-- Name: leave_balances leave_balances_employee_id_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_year_key UNIQUE (employee_id, year);


--
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id);


--
-- Name: meeting_rooms meeting_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meeting_rooms
    ADD CONSTRAINT meeting_rooms_pkey PRIMARY KEY (id);


--
-- Name: msgraph_subscriptions msgraph_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: msgraph_subscriptions msgraph_subscriptions_subscription_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_subscription_id_key UNIQUE (subscription_id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_token_key UNIQUE (token);


--
-- Name: permissions permissions_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_code_key UNIQUE (code);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: room_graph_mappings room_graph_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_pkey PRIMARY KEY (id);


--
-- Name: room_graph_mappings room_graph_mappings_resource_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_resource_email_key UNIQUE (resource_email);


--
-- Name: room_reservations room_reservations_booking_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_booking_token_key UNIQUE (booking_token);


--
-- Name: room_reservations room_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: vacation_request_history vacation_request_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_pkey PRIMARY KEY (id);


--
-- Name: vacation_requests vacation_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_requests
    ADD CONSTRAINT vacation_requests_pkey PRIMARY KEY (id);


--
-- Name: vacation_types vacation_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_types
    ADD CONSTRAINT vacation_types_code_key UNIQUE (code);


--
-- Name: vacation_types vacation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_types
    ADD CONSTRAINT vacation_types_pkey PRIMARY KEY (id);


--
-- Name: idx_approval_level_members_level_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_approval_level_members_level_id ON public.approval_level_members USING btree (level_id);


--
-- Name: idx_approval_level_members_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_approval_level_members_user_id ON public.approval_level_members USING btree (user_id);


--
-- Name: idx_approval_levels_step_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_approval_levels_step_order ON public.approval_levels USING btree (step_order);


--
-- Name: idx_approval_steps_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_approval_steps_request_id ON public.approval_workflow_steps USING btree (request_id);


--
-- Name: idx_approval_steps_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_approval_steps_status ON public.approval_workflow_steps USING btree (status);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_entity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_blackout_dates_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blackout_dates_end_date ON public.blackout_dates USING btree (end_date);


--
-- Name: idx_blackout_dates_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_blackout_dates_start_date ON public.blackout_dates USING btree (start_date);


--
-- Name: idx_meeting_rooms_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_meeting_rooms_status ON public.meeting_rooms USING btree (status);


--
-- Name: idx_permissions_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissions_code ON public.permissions USING btree (code);


--
-- Name: idx_permissions_module; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissions_module ON public.permissions USING btree (module);


--
-- Name: idx_positions_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_parent_id ON public.positions USING btree (parent_id);


--
-- Name: idx_reset_tokens_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reset_tokens_token ON public.password_reset_tokens USING btree (token);


--
-- Name: idx_roles_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_roles_name ON public.roles USING btree (name);


--
-- Name: idx_room_reservations_ical_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_room_reservations_ical_uid ON public.room_reservations USING btree (ical_uid) WHERE (ical_uid IS NOT NULL);


--
-- Name: idx_room_reservations_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_room_reservations_room_id ON public.room_reservations USING btree (room_id);


--
-- Name: idx_room_reservations_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_room_reservations_start_time ON public.room_reservations USING btree (start_time);


--
-- Name: idx_room_reservations_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_room_reservations_token ON public.room_reservations USING btree (booking_token);


--
-- Name: idx_room_reservations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_room_reservations_user_id ON public.room_reservations USING btree (user_id);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_employee_no; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_users_employee_no ON public.users USING btree (employee_no) WHERE (employee_no IS NOT NULL);


--
-- Name: idx_users_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_permission ON public.users USING btree (permission);


--
-- Name: idx_users_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: idx_vacation_request_history_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vacation_request_history_request_id ON public.vacation_request_history USING btree (request_id);


--
-- Name: idx_vacation_requests_employee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vacation_requests_employee_id ON public.vacation_requests USING btree (employee_id);


--
-- Name: idx_vacation_requests_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vacation_requests_start_date ON public.vacation_requests USING btree (start_date);


--
-- Name: idx_vacation_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vacation_requests_status ON public.vacation_requests USING btree (status);


--
-- Name: approval_level_members approval_level_members_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.approval_levels(id) ON DELETE CASCADE;


--
-- Name: approval_level_members approval_level_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_level_members
    ADD CONSTRAINT approval_level_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: approval_levels approval_levels_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_levels
    ADD CONSTRAINT approval_levels_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.approval_levels(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_level_id_fkey FOREIGN KEY (level_id) REFERENCES public.approval_levels(id) ON DELETE SET NULL;


--
-- Name: approval_workflow_steps approval_workflow_steps_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.approval_workflow_steps
    ADD CONSTRAINT approval_workflow_steps_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.vacation_requests(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: blackout_dates blackout_dates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blackout_dates
    ADD CONSTRAINT blackout_dates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: leave_balances leave_balances_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: msgraph_subscriptions msgraph_subscriptions_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.msgraph_subscriptions
    ADD CONSTRAINT msgraph_subscriptions_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE SET NULL;


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: positions positions_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.positions(id) ON DELETE SET NULL;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: room_graph_mappings room_graph_mappings_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_graph_mappings
    ADD CONSTRAINT room_graph_mappings_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE CASCADE;


--
-- Name: room_reservations room_reservations_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.meeting_rooms(id) ON DELETE CASCADE;


--
-- Name: room_reservations room_reservations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_reservations
    ADD CONSTRAINT room_reservations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id) ON DELETE SET NULL;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE SET NULL;


--
-- Name: vacation_request_history vacation_request_history_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: vacation_request_history vacation_request_history_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_request_history
    ADD CONSTRAINT vacation_request_history_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.vacation_requests(id) ON DELETE CASCADE;


--
-- Name: vacation_requests vacation_requests_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacation_requests
    ADD CONSTRAINT vacation_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 8MUQK21Mso0c6XdLgi0M2PQuN2N4IYww0T1L2kDm0GYH7NhuAhNhEKlZHXQqak3

