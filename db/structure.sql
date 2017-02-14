--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: code_harbor_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE code_harbor_links (
    id integer NOT NULL,
    oauth2token character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: code_harbor_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE code_harbor_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: code_harbor_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE code_harbor_links_id_seq OWNED BY code_harbor_links.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE comments (
    id integer NOT NULL,
    user_id integer,
    file_id integer,
    user_type character varying,
    "row" integer,
    "column" integer,
    text text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: consumers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consumers (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    oauth_key character varying,
    oauth_secret character varying
);


--
-- Name: consumers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consumers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consumers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consumers_id_seq OWNED BY consumers.id;


--
-- Name: errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE errors (
    id integer NOT NULL,
    execution_environment_id integer,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    submission_id integer
);


--
-- Name: errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE errors_id_seq OWNED BY errors.id;


--
-- Name: execution_environments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE execution_environments (
    id integer NOT NULL,
    docker_image character varying,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    run_command character varying,
    test_command character varying,
    testing_framework character varying,
    help text,
    exposed_ports character varying,
    permitted_execution_time integer,
    user_id integer,
    user_type character varying,
    pool_size integer,
    file_type_id integer,
    memory_limit integer,
    network_enabled boolean
);


--
-- Name: execution_environments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE execution_environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: execution_environments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE execution_environments_id_seq OWNED BY execution_environments.id;


--
-- Name: exercises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE exercises (
    id integer NOT NULL,
    description text,
    execution_environment_id integer,
    title character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    instructions text,
    public boolean,
    user_type character varying,
    token character varying,
    hide_file_tree boolean,
    allow_file_creation boolean,
    allow_auto_completion boolean DEFAULT false
);


--
-- Name: exercises_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE exercises_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exercises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE exercises_id_seq OWNED BY exercises.id;


--
-- Name: external_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE external_users (
    id integer NOT NULL,
    consumer_id integer,
    email character varying,
    external_id character varying,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: external_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE external_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: external_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE external_users_id_seq OWNED BY external_users.id;


--
-- Name: file_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE file_templates (
    id integer NOT NULL,
    name character varying,
    content text,
    file_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: file_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE file_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: file_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE file_templates_id_seq OWNED BY file_templates.id;


--
-- Name: file_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE file_types (
    id integer NOT NULL,
    editor_mode character varying,
    file_extension character varying,
    indent_size integer,
    name character varying,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    executable boolean,
    renderable boolean,
    user_type character varying,
    "binary" boolean
);


--
-- Name: file_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE file_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: file_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE file_types_id_seq OWNED BY file_types.id;


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE files (
    id integer NOT NULL,
    content text,
    context_id integer,
    context_type character varying,
    file_id integer,
    file_type_id integer,
    hidden boolean,
    name character varying,
    read_only boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    native_file character varying,
    role character varying,
    hashed_content character varying,
    feedback_message character varying,
    weight double precision,
    path character varying,
    file_template_id integer
);


--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE files_id_seq OWNED BY files.id;


--
-- Name: hints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hints (
    id integer NOT NULL,
    execution_environment_id integer,
    locale character varying,
    message text,
    name character varying,
    regular_expression character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: hints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hints_id_seq OWNED BY hints.id;


--
-- Name: internal_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE internal_users (
    id integer NOT NULL,
    consumer_id integer,
    email character varying,
    name character varying,
    role character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    crypted_password character varying,
    salt character varying,
    failed_logins_count integer DEFAULT 0,
    lock_expires_at timestamp without time zone,
    unlock_token character varying,
    remember_me_token character varying,
    remember_me_token_expires_at timestamp without time zone,
    reset_password_token character varying,
    reset_password_token_expires_at timestamp without time zone,
    reset_password_email_sent_at timestamp without time zone,
    activation_state character varying,
    activation_token character varying,
    activation_token_expires_at timestamp without time zone
);


--
-- Name: internal_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE internal_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: internal_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE internal_users_id_seq OWNED BY internal_users.id;


--
-- Name: lti_parameters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE lti_parameters (
    id integer NOT NULL,
    external_users_id integer,
    consumers_id integer,
    exercises_id integer,
    lti_parameters jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: lti_parameters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lti_parameters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lti_parameters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE lti_parameters_id_seq OWNED BY lti_parameters.id;


--
-- Name: remote_evaluation_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE remote_evaluation_mappings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    exercise_id integer NOT NULL,
    validation_token character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: remote_evaluation_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE remote_evaluation_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: remote_evaluation_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE remote_evaluation_mappings_id_seq OWNED BY remote_evaluation_mappings.id;


--
-- Name: request_for_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE request_for_comments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    exercise_id integer NOT NULL,
    file_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_type character varying,
    question text,
    solved boolean,
    submission_id integer
);


--
-- Name: request_for_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE request_for_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_for_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE request_for_comments_id_seq OWNED BY request_for_comments.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE submissions (
    id integer NOT NULL,
    exercise_id integer,
    score double precision,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cause character varying,
    user_type character varying
);


--
-- Name: submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE submissions_id_seq OWNED BY submissions.id;


--
-- Name: testruns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE testruns (
    id integer NOT NULL,
    passed boolean,
    output text,
    file_id integer,
    submission_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: testruns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE testruns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: testruns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE testruns_id_seq OWNED BY testruns.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY code_harbor_links ALTER COLUMN id SET DEFAULT nextval('code_harbor_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consumers ALTER COLUMN id SET DEFAULT nextval('consumers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY errors ALTER COLUMN id SET DEFAULT nextval('errors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY execution_environments ALTER COLUMN id SET DEFAULT nextval('execution_environments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY exercises ALTER COLUMN id SET DEFAULT nextval('exercises_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_users ALTER COLUMN id SET DEFAULT nextval('external_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY file_templates ALTER COLUMN id SET DEFAULT nextval('file_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY file_types ALTER COLUMN id SET DEFAULT nextval('file_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY files ALTER COLUMN id SET DEFAULT nextval('files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hints ALTER COLUMN id SET DEFAULT nextval('hints_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY internal_users ALTER COLUMN id SET DEFAULT nextval('internal_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_parameters ALTER COLUMN id SET DEFAULT nextval('lti_parameters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY remote_evaluation_mappings ALTER COLUMN id SET DEFAULT nextval('remote_evaluation_mappings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY request_for_comments ALTER COLUMN id SET DEFAULT nextval('request_for_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions ALTER COLUMN id SET DEFAULT nextval('submissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY testruns ALTER COLUMN id SET DEFAULT nextval('testruns_id_seq'::regclass);


--
-- Name: code_harbor_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY code_harbor_links
    ADD CONSTRAINT code_harbor_links_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: consumers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consumers
    ADD CONSTRAINT consumers_pkey PRIMARY KEY (id);


--
-- Name: errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY errors
    ADD CONSTRAINT errors_pkey PRIMARY KEY (id);


--
-- Name: execution_environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY execution_environments
    ADD CONSTRAINT execution_environments_pkey PRIMARY KEY (id);


--
-- Name: exercises_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY exercises
    ADD CONSTRAINT exercises_pkey PRIMARY KEY (id);


--
-- Name: external_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_users
    ADD CONSTRAINT external_users_pkey PRIMARY KEY (id);


--
-- Name: file_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY file_templates
    ADD CONSTRAINT file_templates_pkey PRIMARY KEY (id);


--
-- Name: file_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY file_types
    ADD CONSTRAINT file_types_pkey PRIMARY KEY (id);


--
-- Name: files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: hints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hints
    ADD CONSTRAINT hints_pkey PRIMARY KEY (id);


--
-- Name: internal_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY internal_users
    ADD CONSTRAINT internal_users_pkey PRIMARY KEY (id);


--
-- Name: lti_parameters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY lti_parameters
    ADD CONSTRAINT lti_parameters_pkey PRIMARY KEY (id);


--
-- Name: remote_evaluation_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY remote_evaluation_mappings
    ADD CONSTRAINT remote_evaluation_mappings_pkey PRIMARY KEY (id);


--
-- Name: request_for_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY request_for_comments
    ADD CONSTRAINT request_for_comments_pkey PRIMARY KEY (id);


--
-- Name: submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submissions
    ADD CONSTRAINT submissions_pkey PRIMARY KEY (id);


--
-- Name: testruns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY testruns
    ADD CONSTRAINT testruns_pkey PRIMARY KEY (id);


--
-- Name: index_comments_on_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_file_id ON comments USING btree (file_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON comments USING btree (user_id);


--
-- Name: index_errors_on_submission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_errors_on_submission_id ON errors USING btree (submission_id);


--
-- Name: index_files_on_context_id_and_context_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_files_on_context_id_and_context_type ON files USING btree (context_id, context_type);


--
-- Name: index_internal_users_on_activation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_internal_users_on_activation_token ON internal_users USING btree (activation_token);


--
-- Name: index_internal_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_internal_users_on_email ON internal_users USING btree (email);


--
-- Name: index_internal_users_on_remember_me_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_internal_users_on_remember_me_token ON internal_users USING btree (remember_me_token);


--
-- Name: index_internal_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_internal_users_on_reset_password_token ON internal_users USING btree (reset_password_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20140625134118');

INSERT INTO schema_migrations (version) VALUES ('20140626143132');

INSERT INTO schema_migrations (version) VALUES ('20140626144036');

INSERT INTO schema_migrations (version) VALUES ('20140630093736');

INSERT INTO schema_migrations (version) VALUES ('20140630111215');

INSERT INTO schema_migrations (version) VALUES ('20140701120126');

INSERT INTO schema_migrations (version) VALUES ('20140701122345');

INSERT INTO schema_migrations (version) VALUES ('20140702100130');

INSERT INTO schema_migrations (version) VALUES ('20140703070749');

INSERT INTO schema_migrations (version) VALUES ('20140716153147');

INSERT INTO schema_migrations (version) VALUES ('20140717074902');

INSERT INTO schema_migrations (version) VALUES ('20140722125431');

INSERT INTO schema_migrations (version) VALUES ('20140723135530');

INSERT INTO schema_migrations (version) VALUES ('20140723135747');

INSERT INTO schema_migrations (version) VALUES ('20140724155359');

INSERT INTO schema_migrations (version) VALUES ('20140730114343');

INSERT INTO schema_migrations (version) VALUES ('20140730115010');

INSERT INTO schema_migrations (version) VALUES ('20140805161431');

INSERT INTO schema_migrations (version) VALUES ('20140812102114');

INSERT INTO schema_migrations (version) VALUES ('20140812144733');

INSERT INTO schema_migrations (version) VALUES ('20140812150607');

INSERT INTO schema_migrations (version) VALUES ('20140812150925');

INSERT INTO schema_migrations (version) VALUES ('20140813091722');

INSERT INTO schema_migrations (version) VALUES ('20140820170039');

INSERT INTO schema_migrations (version) VALUES ('20140821064318');

INSERT INTO schema_migrations (version) VALUES ('20140823172643');

INSERT INTO schema_migrations (version) VALUES ('20140823173923');

INSERT INTO schema_migrations (version) VALUES ('20140825121336');

INSERT INTO schema_migrations (version) VALUES ('20140825125801');

INSERT INTO schema_migrations (version) VALUES ('20140825154202');

INSERT INTO schema_migrations (version) VALUES ('20140825161350');

INSERT INTO schema_migrations (version) VALUES ('20140825161358');

INSERT INTO schema_migrations (version) VALUES ('20140825161406');

INSERT INTO schema_migrations (version) VALUES ('20140826073318');

INSERT INTO schema_migrations (version) VALUES ('20140826073319');

INSERT INTO schema_migrations (version) VALUES ('20140826073320');

INSERT INTO schema_migrations (version) VALUES ('20140826073321');

INSERT INTO schema_migrations (version) VALUES ('20140826073322');

INSERT INTO schema_migrations (version) VALUES ('20140827065359');

INSERT INTO schema_migrations (version) VALUES ('20140827083957');

INSERT INTO schema_migrations (version) VALUES ('20140829141913');

INSERT INTO schema_migrations (version) VALUES ('20140903093436');

INSERT INTO schema_migrations (version) VALUES ('20140903165113');

INSERT INTO schema_migrations (version) VALUES ('20140904082810');

INSERT INTO schema_migrations (version) VALUES ('20140909115430');

INSERT INTO schema_migrations (version) VALUES ('20140915095420');

INSERT INTO schema_migrations (version) VALUES ('20140915122846');

INSERT INTO schema_migrations (version) VALUES ('20140918063522');

INSERT INTO schema_migrations (version) VALUES ('20140922161120');

INSERT INTO schema_migrations (version) VALUES ('20140922161226');

INSERT INTO schema_migrations (version) VALUES ('20141003072729');

INSERT INTO schema_migrations (version) VALUES ('20141004114747');

INSERT INTO schema_migrations (version) VALUES ('20141009110434');

INSERT INTO schema_migrations (version) VALUES ('20141011145303');

INSERT INTO schema_migrations (version) VALUES ('20141017110211');

INSERT INTO schema_migrations (version) VALUES ('20141031161603');

INSERT INTO schema_migrations (version) VALUES ('20141119131607');

INSERT INTO schema_migrations (version) VALUES ('20150128083123');

INSERT INTO schema_migrations (version) VALUES ('20150128084834');

INSERT INTO schema_migrations (version) VALUES ('20150128093003');

INSERT INTO schema_migrations (version) VALUES ('20150204080832');

INSERT INTO schema_migrations (version) VALUES ('20150310150712');

INSERT INTO schema_migrations (version) VALUES ('20150317083739');

INSERT INTO schema_migrations (version) VALUES ('20150317115338');

INSERT INTO schema_migrations (version) VALUES ('20150327141740');

INSERT INTO schema_migrations (version) VALUES ('20150408155923');

INSERT INTO schema_migrations (version) VALUES ('20150421074734');

INSERT INTO schema_migrations (version) VALUES ('20150818141554');

INSERT INTO schema_migrations (version) VALUES ('20150818142251');

INSERT INTO schema_migrations (version) VALUES ('20150903152727');

INSERT INTO schema_migrations (version) VALUES ('20150922125415');

INSERT INTO schema_migrations (version) VALUES ('20160204094409');

INSERT INTO schema_migrations (version) VALUES ('20160204111716');

INSERT INTO schema_migrations (version) VALUES ('20160302133540');

INSERT INTO schema_migrations (version) VALUES ('20160426114951');

INSERT INTO schema_migrations (version) VALUES ('20160510145341');

INSERT INTO schema_migrations (version) VALUES ('20160512131539');

INSERT INTO schema_migrations (version) VALUES ('20160609185708');

INSERT INTO schema_migrations (version) VALUES ('20160610111602');

INSERT INTO schema_migrations (version) VALUES ('20160624130951');

INSERT INTO schema_migrations (version) VALUES ('20160630154310');

INSERT INTO schema_migrations (version) VALUES ('20160701092140');

INSERT INTO schema_migrations (version) VALUES ('20160704143402');

INSERT INTO schema_migrations (version) VALUES ('20160907123009');

INSERT INTO schema_migrations (version) VALUES ('20170112151637');

INSERT INTO schema_migrations (version) VALUES ('20170202170437');

