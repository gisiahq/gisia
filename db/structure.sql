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

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id bigint NOT NULL,
    trackable_type character varying NOT NULL,
    trackable_id bigint NOT NULL,
    author_id bigint,
    action_type smallint NOT NULL,
    note_id bigint,
    details jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    details_html text
)
PARTITION BY LIST (trackable_type);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


SET default_table_access_method = heap;

--
-- Name: application_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_settings (
    id bigint NOT NULL,
    default_branch_name text,
    disable_feed_token boolean DEFAULT false NOT NULL,
    enabled_git_access_protocol character varying,
    receive_max_input_size integer,
    gitlab_dedicated_instance boolean DEFAULT false NOT NULL,
    admin_mode boolean DEFAULT false NOT NULL,
    ci_cd_settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    allow_runner_registration_token boolean DEFAULT true NOT NULL,
    valid_runner_registrars character varying[] DEFAULT '{project,group}'::character varying[],
    runner_token_expiration_interval integer,
    runners_registration_token_encrypted character varying,
    max_attachment_size integer DEFAULT 100 NOT NULL,
    require_personal_access_token_expiry boolean DEFAULT true NOT NULL,
    hashed_storage_enabled boolean DEFAULT true NOT NULL,
    diff_max_files integer DEFAULT 1000 NOT NULL,
    diff_max_lines integer DEFAULT 50000 NOT NULL,
    diff_max_patch_bytes integer DEFAULT 204800 NOT NULL,
    custom_http_clone_url_root character varying(511),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    rsa_key_restriction integer DEFAULT 0 NOT NULL,
    dsa_key_restriction integer DEFAULT 0 NOT NULL,
    ecdsa_key_restriction integer DEFAULT 0 NOT NULL,
    ecdsa_sk_key_restriction integer DEFAULT 0 NOT NULL,
    ed25519_key_restriction integer DEFAULT 0 NOT NULL,
    ed25519_sk_key_restriction integer DEFAULT 0 NOT NULL,
    gitaly_timeout_default integer DEFAULT 55 NOT NULL,
    gitaly_timeout_fast integer DEFAULT 10 NOT NULL,
    gitaly_timeout_medium integer DEFAULT 30 NOT NULL,
    plantuml_enabled boolean DEFAULT false NOT NULL,
    plantuml_url character varying,
    ci_max_includes integer DEFAULT 150 NOT NULL,
    ci_max_total_yaml_size_bytes integer DEFAULT 314572800 NOT NULL,
    personal_access_token_prefix text DEFAULT 'gspat-'::text,
    repository_storages_weighted jsonb DEFAULT '{}'::jsonb NOT NULL,
    gitlab_shell_operation_limit integer DEFAULT 600,
    pipeline_limit_per_project_user_sha integer DEFAULT 0 NOT NULL,
    max_yaml_depth integer DEFAULT 100 NOT NULL,
    max_yaml_size_bytes bigint DEFAULT 2097152 NOT NULL,
    encrypted_ci_job_token_signing_key bytea,
    encrypted_ci_job_token_signing_key_iv bytea,
    encrypted_ci_jwt_signing_key text,
    encrypted_ci_jwt_signing_key_iv text,
    unique_ips_limit_enabled boolean DEFAULT false NOT NULL,
    unique_ips_limit_per_user integer DEFAULT 10,
    unique_ips_limit_time_window integer DEFAULT 3600,
    external_pipeline_validation_service_timeout integer,
    external_pipeline_validation_service_url text,
    encrypted_external_pipeline_validation_service_token text,
    encrypted_external_pipeline_validation_service_token_iv text,
    password_authentication_enabled_for_git boolean DEFAULT true NOT NULL,
    password_authentication_enabled_for_web boolean,
    commit_email_hostname character varying
);


--
-- Name: application_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.application_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.application_settings_id_seq OWNED BY public.application_settings.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: board_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.board_stages (
    id bigint NOT NULL,
    board_id bigint NOT NULL,
    title character varying,
    label_ids jsonb DEFAULT '[]'::jsonb NOT NULL,
    rank integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    kind integer DEFAULT 1
);


--
-- Name: board_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.board_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.board_stages_id_seq OWNED BY public.board_stages.id;


--
-- Name: boards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boards (
    id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    updated_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    title character varying DEFAULT 'Default'::character varying
);


--
-- Name: boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.boards_id_seq OWNED BY public.boards.id;


--
-- Name: ci_build_needs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_needs (
    id bigint NOT NULL,
    name text NOT NULL,
    artifacts boolean DEFAULT true NOT NULL,
    optional boolean DEFAULT false NOT NULL,
    build_id bigint NOT NULL,
    project_id bigint
);


--
-- Name: ci_build_needs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_build_needs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_build_needs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_build_needs_id_seq OWNED BY public.ci_build_needs.id;


--
-- Name: ci_build_pending_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_pending_states (
    id bigint NOT NULL,
    build_id bigint NOT NULL,
    state integer,
    failure_reason integer,
    trace_checksum bytea,
    trace_bytesize bigint,
    project_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_build_pending_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_build_pending_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_build_pending_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_build_pending_states_id_seq OWNED BY public.ci_build_pending_states.id;


--
-- Name: ci_build_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_sources (
    build_id bigint NOT NULL,
    project_id bigint NOT NULL,
    source smallint,
    pipeline_source smallint
);


--
-- Name: ci_build_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_tags (
    id bigint NOT NULL,
    tag_id bigint NOT NULL,
    build_id bigint NOT NULL,
    project_id bigint NOT NULL
);


--
-- Name: ci_build_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_build_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_build_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_build_tags_id_seq OWNED BY public.ci_build_tags.id;


--
-- Name: ci_build_trace_chunks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_trace_chunks (
    id bigint NOT NULL,
    chunk_index integer DEFAULT 0 NOT NULL,
    data_store integer DEFAULT 0 NOT NULL,
    raw_data bytea,
    checksum bytea,
    lock_version integer DEFAULT 0 NOT NULL,
    build_id bigint NOT NULL,
    project_id bigint
);


--
-- Name: ci_build_trace_chunks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_build_trace_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_build_trace_chunks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_build_trace_chunks_id_seq OWNED BY public.ci_build_trace_chunks.id;


--
-- Name: ci_build_trace_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_build_trace_metadata (
    id bigint NOT NULL,
    build_id bigint NOT NULL,
    trace_artifact_id bigint,
    last_archival_attempt_at timestamp with time zone,
    archived_at timestamp with time zone,
    archival_attempts smallint DEFAULT 0 NOT NULL,
    checksum bytea,
    remote_checksum bytea,
    project_id bigint
);


--
-- Name: ci_build_trace_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_build_trace_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_build_trace_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_build_trace_metadata_id_seq OWNED BY public.ci_build_trace_metadata.id;


--
-- Name: ci_builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_builds (
    id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    finished_at timestamp(6) without time zone,
    started_at timestamp(6) without time zone,
    name character varying NOT NULL,
    allow_failure boolean DEFAULT false NOT NULL,
    stage_idx integer NOT NULL,
    ref character varying NOT NULL,
    artifacts_expire_at timestamp(6) without time zone,
    yaml_variables text,
    queued_at timestamp(6) without time zone,
    retried boolean DEFAULT false NOT NULL,
    failure_reason integer,
    scheduled_at timestamp(6) without time zone,
    stage_id bigint NOT NULL,
    commit_id bigint NOT NULL,
    project_id bigint NOT NULL,
    runner_id bigint,
    upstream_pipeline_id bigint,
    user_id bigint NOT NULL,
    "when" character varying,
    scheduling_type integer,
    tag boolean,
    protected boolean,
    options jsonb,
    coverage double precision,
    target_url character varying,
    erased_at timestamp(6) without time zone,
    environment character varying,
    coverage_regex character varying,
    token_encrypted character varying,
    resource_group_id bigint,
    waiting_for_resource_at timestamp(6) without time zone,
    processed boolean DEFAULT false,
    auto_canceled_by_id bigint,
    erased_by_id bigint,
    trigger_request_id bigint,
    execution_config_id bigint,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lock_version integer DEFAULT 0,
    type integer DEFAULT 0 NOT NULL,
    exit_code integer
);


--
-- Name: ci_builds_execution_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_builds_execution_configs (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    run_steps jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: ci_builds_execution_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_builds_execution_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_builds_execution_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_builds_execution_configs_id_seq OWNED BY public.ci_builds_execution_configs.id;


--
-- Name: ci_builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_builds_id_seq OWNED BY public.ci_builds.id;


--
-- Name: ci_builds_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_builds_metadata (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    timeout integer,
    timeout_source integer DEFAULT 1 NOT NULL,
    interruptible boolean,
    config_options jsonb,
    config_variables jsonb,
    has_exposed_artifacts boolean,
    environment_auto_stop_in character varying(255),
    expanded_environment_name character varying(255),
    secrets jsonb DEFAULT '{}'::jsonb NOT NULL,
    build_id bigint NOT NULL,
    id_tokens jsonb DEFAULT '{}'::jsonb NOT NULL,
    debug_trace_enabled boolean DEFAULT false NOT NULL,
    exit_code smallint
);


--
-- Name: ci_builds_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_builds_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_builds_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_builds_metadata_id_seq OWNED BY public.ci_builds_metadata.id;


--
-- Name: ci_builds_runner_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_builds_runner_session (
    id bigint NOT NULL,
    url character varying NOT NULL,
    certificate character varying,
    "authorization" character varying,
    build_id bigint NOT NULL,
    project_id bigint
);


--
-- Name: ci_builds_runner_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_builds_runner_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_builds_runner_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_builds_runner_session_id_seq OWNED BY public.ci_builds_runner_session.id;


--
-- Name: ci_instance_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_instance_variables (
    id bigint NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL,
    masked boolean DEFAULT false,
    protected boolean DEFAULT false,
    key text NOT NULL,
    encrypted_value text,
    encrypted_value_iv text,
    raw boolean DEFAULT false NOT NULL,
    description text
);


--
-- Name: ci_instance_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_instance_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_instance_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_instance_variables_id_seq OWNED BY public.ci_instance_variables.id;


--
-- Name: ci_job_artifacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_job_artifacts (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    file_type integer NOT NULL,
    size bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    expire_at timestamp(6) without time zone,
    file character varying,
    file_store integer DEFAULT 1,
    file_sha256 bytea,
    file_format integer,
    file_location integer,
    job_id bigint NOT NULL,
    locked integer DEFAULT 2,
    accessibility integer DEFAULT 0 NOT NULL,
    file_final_path text,
    exposed_as text,
    exposed_paths text[]
);


--
-- Name: ci_job_artifacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_job_artifacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_job_artifacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_job_artifacts_id_seq OWNED BY public.ci_job_artifacts.id;


--
-- Name: ci_job_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_job_variables (
    id bigint NOT NULL,
    key character varying NOT NULL,
    encrypted_value text,
    encrypted_value_iv character varying,
    job_id bigint NOT NULL,
    variable_type integer DEFAULT 1 NOT NULL,
    source integer DEFAULT 0 NOT NULL,
    raw boolean DEFAULT false NOT NULL,
    project_id bigint
);


--
-- Name: ci_job_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_job_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_job_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_job_variables_id_seq OWNED BY public.ci_job_variables.id;


--
-- Name: ci_pending_builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pending_builds (
    id bigint NOT NULL,
    build_id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    instance_runners_enabled boolean DEFAULT false NOT NULL,
    namespace_id bigint,
    minutes_exceeded boolean DEFAULT false NOT NULL,
    tag_ids bigint[] DEFAULT '{}'::bigint[],
    namespace_traversal_ids bigint[] DEFAULT '{}'::bigint[],
    plan_id bigint
);


--
-- Name: ci_pending_builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_pending_builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_pending_builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_pending_builds_id_seq OWNED BY public.ci_pending_builds.id;


--
-- Name: ci_pipeline_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pipeline_messages (
    id bigint NOT NULL,
    severity smallint DEFAULT 0 NOT NULL,
    content text NOT NULL,
    pipeline_id bigint NOT NULL,
    project_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_pipeline_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_pipeline_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_pipeline_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_pipeline_messages_id_seq OWNED BY public.ci_pipeline_messages.id;


--
-- Name: ci_pipeline_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pipeline_metadata (
    project_id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    name text,
    auto_cancel_on_new_commit integer DEFAULT 0 NOT NULL,
    auto_cancel_on_job_failure integer DEFAULT 0 NOT NULL
);


--
-- Name: ci_pipeline_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pipeline_variables (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    variable_type smallint DEFAULT 1 NOT NULL,
    raw boolean DEFAULT false NOT NULL,
    pipeline_id bigint NOT NULL,
    project_id bigint
);


--
-- Name: ci_pipeline_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_pipeline_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_pipeline_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_pipeline_variables_id_seq OWNED BY public.ci_pipeline_variables.id;


--
-- Name: ci_pipelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pipelines (
    id bigint NOT NULL,
    ref character varying NOT NULL,
    sha character varying NOT NULL,
    yaml_errors text,
    project_id bigint NOT NULL,
    status character varying,
    finished_at timestamp(6) without time zone,
    duration integer,
    failure_reason integer,
    merge_request_id bigint,
    trigger_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    source integer DEFAULT 0 NOT NULL,
    before_sha character varying,
    target_sha character varying,
    source_sha character varying,
    user_id bigint NOT NULL,
    tag boolean DEFAULT false NOT NULL,
    iid integer NOT NULL,
    config_source integer,
    locked integer DEFAULT 1 NOT NULL,
    started_at timestamp(6) without time zone,
    protected boolean DEFAULT false NOT NULL,
    pipeline_schedule_id bigint,
    auto_canceled_by_id bigint,
    committed_at timestamp(6) without time zone,
    ci_ref_id bigint,
    lock_version integer DEFAULT 0
);


--
-- Name: ci_pipelines_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_pipelines_configs (
    pipeline_id bigint NOT NULL,
    content text NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_pipelines_id_seq OWNED BY public.ci_pipelines.id;


--
-- Name: ci_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_refs (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    ref_path text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_refs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_refs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_refs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_refs_id_seq OWNED BY public.ci_refs.id;


--
-- Name: ci_runner_machine_builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_runner_machine_builds (
    build_id bigint NOT NULL,
    runner_machine_id bigint NOT NULL,
    project_id bigint
);


--
-- Name: ci_runner_machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_runner_machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_runner_machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_runner_machines (
    id bigint DEFAULT nextval('public.ci_runner_machines_id_seq'::regclass) NOT NULL,
    runner_id bigint NOT NULL,
    sharding_key_id bigint,
    contacted_at timestamp(6) without time zone,
    creation_state integer DEFAULT 0 NOT NULL,
    executor_type integer,
    runner_type integer NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    system_xid text NOT NULL,
    platform text,
    architecture text,
    revision text,
    ip_address text,
    version text,
    runtime_features jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_runner_taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_runner_taggings (
    id bigint NOT NULL,
    tag_id bigint NOT NULL,
    runner_id bigint NOT NULL,
    sharding_key_id bigint,
    runner_type integer NOT NULL
);


--
-- Name: ci_runner_taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_runner_taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_runner_taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_runner_taggings_id_seq OWNED BY public.ci_runner_taggings.id;


--
-- Name: ci_runner_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_runner_versions (
    version text NOT NULL,
    status integer
);


--
-- Name: ci_runners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_runners (
    id bigint NOT NULL,
    creator_id bigint,
    contacted_at timestamp(6) without time zone,
    token_expires_at timestamp(6) without time zone,
    access_level integer DEFAULT 0 NOT NULL,
    maximum_timeout integer,
    runner_type integer NOT NULL,
    registration_type integer DEFAULT 0 NOT NULL,
    creation_state integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    run_untagged boolean DEFAULT true NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    name text,
    token_encrypted text,
    token text,
    description text,
    maintainer_note text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    sharding_key_id bigint
);


--
-- Name: ci_runners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_runners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_runners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_runners_id_seq OWNED BY public.ci_runners.id;


--
-- Name: ci_running_builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_running_builds (
    id bigint NOT NULL,
    build_id bigint NOT NULL,
    project_id bigint NOT NULL,
    runner_id bigint NOT NULL,
    runner_type integer NOT NULL,
    runner_owner_namespace_xid bigint,
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL
);


--
-- Name: ci_running_builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_running_builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_running_builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_running_builds_id_seq OWNED BY public.ci_running_builds.id;


--
-- Name: ci_sources_pipelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_sources_pipelines (
    id bigint NOT NULL,
    project_id bigint,
    source_project_id bigint,
    source_job_id bigint,
    pipeline_id bigint,
    source_pipeline_id bigint
);


--
-- Name: ci_sources_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_sources_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_sources_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_sources_pipelines_id_seq OWNED BY public.ci_sources_pipelines.id;


--
-- Name: ci_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_stages (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    name character varying NOT NULL,
    status integer DEFAULT 0,
    "position" integer,
    pipeline_id bigint NOT NULL,
    lock_version integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_stages_id_seq OWNED BY public.ci_stages.id;


--
-- Name: ci_triggers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_triggers (
    id bigint NOT NULL,
    token character varying NOT NULL,
    project_id bigint NOT NULL,
    owner_id bigint NOT NULL,
    description character varying,
    encrypted_token bytea,
    encrypted_token_iv bytea,
    expires_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    token_encrypted text
);


--
-- Name: ci_triggers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_triggers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_triggers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_triggers_id_seq OWNED BY public.ci_triggers.id;


--
-- Name: ci_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_variables (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value text,
    encrypted_value text,
    encrypted_value_salt character varying,
    encrypted_value_iv character varying,
    namespace_id bigint NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    environment_scope character varying DEFAULT '*'::character varying NOT NULL,
    masked boolean DEFAULT false NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL,
    raw boolean DEFAULT false NOT NULL,
    description text,
    hidden boolean DEFAULT false NOT NULL
);


--
-- Name: ci_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_variables_id_seq OWNED BY public.ci_variables.id;


--
-- Name: epic_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_activities (
    id bigint DEFAULT nextval('public.activities_id_seq'::regclass) NOT NULL,
    trackable_type character varying NOT NULL,
    trackable_id bigint NOT NULL,
    author_id bigint,
    action_type smallint NOT NULL,
    note_id bigint,
    details jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    details_html text
);


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    note text,
    noteable_type character varying NOT NULL,
    noteable_id bigint,
    author_id bigint NOT NULL,
    updated_by_id bigint,
    discussion_id character varying,
    system boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    resolved_at timestamp(6) without time zone,
    resolved_by_id bigint,
    confidential boolean,
    last_edited_at timestamp(6) without time zone,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying NOT NULL,
    note_html text,
    "position" text,
    original_position text,
    change_position text,
    line_code character varying
)
PARTITION BY LIST (noteable_type);


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: epic_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_notes (
    id bigint DEFAULT nextval('public.notes_id_seq'::regclass) NOT NULL,
    note text,
    noteable_type character varying NOT NULL,
    noteable_id bigint,
    author_id bigint NOT NULL,
    updated_by_id bigint,
    discussion_id character varying,
    system boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    resolved_at timestamp(6) without time zone,
    resolved_by_id bigint,
    confidential boolean,
    last_edited_at timestamp(6) without time zone,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying NOT NULL,
    note_html text,
    "position" text,
    original_position text,
    change_position text,
    line_code character varying
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name character varying NOT NULL,
    path character varying NOT NULL,
    description text,
    namespace_id bigint DEFAULT 0 NOT NULL,
    avatar character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: internal_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_ids (
    id bigint NOT NULL,
    project_id bigint,
    usage integer NOT NULL,
    last_value integer NOT NULL,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: internal_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.internal_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: internal_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.internal_ids_id_seq OWNED BY public.internal_ids.id;


--
-- Name: issue_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_activities (
    id bigint DEFAULT nextval('public.activities_id_seq'::regclass) NOT NULL,
    trackable_type character varying NOT NULL,
    trackable_id bigint NOT NULL,
    author_id bigint,
    action_type smallint NOT NULL,
    note_id bigint,
    details jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    details_html text
);


--
-- Name: issue_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_notes (
    id bigint DEFAULT nextval('public.notes_id_seq'::regclass) NOT NULL,
    note text,
    noteable_type character varying NOT NULL,
    noteable_id bigint,
    author_id bigint NOT NULL,
    updated_by_id bigint,
    discussion_id character varying,
    system boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    resolved_at timestamp(6) without time zone,
    resolved_by_id bigint,
    confidential boolean,
    last_edited_at timestamp(6) without time zone,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying NOT NULL,
    note_html text,
    "position" text,
    original_position text,
    change_position text,
    line_code character varying
);


--
-- Name: item_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_links (
    id bigint NOT NULL,
    source_id bigint NOT NULL,
    source_type character varying NOT NULL,
    target_id bigint NOT NULL,
    target_type character varying NOT NULL,
    namespace_id bigint NOT NULL,
    auto_close boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: item_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_links_id_seq OWNED BY public.item_links.id;


--
-- Name: keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.keys (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    key text NOT NULL,
    title character varying NOT NULL,
    fingerprint character varying,
    last_used_at timestamp(6) without time zone,
    fingerprint_sha256 bytea,
    expires_at timestamp(6) without time zone,
    usage_type integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.keys_id_seq OWNED BY public.keys.id;


--
-- Name: label_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_links (
    id bigint NOT NULL,
    label_id bigint NOT NULL,
    labelable_id bigint NOT NULL,
    labelable_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: label_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.label_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: label_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.label_links_id_seq OWNED BY public.label_links.id;


--
-- Name: labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labels (
    id bigint NOT NULL,
    title character varying,
    color character varying,
    description text,
    rank integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    namespace_id bigint
);


--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    id bigint NOT NULL,
    access_level integer DEFAULT 0 NOT NULL,
    user_id bigint NOT NULL,
    created_by_id bigint,
    namespace_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying NOT NULL,
    expires_at date,
    requested_at timestamp(6) without time zone
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.members_id_seq OWNED BY public.members.id;


--
-- Name: merge_request_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_activities (
    id bigint DEFAULT nextval('public.activities_id_seq'::regclass) NOT NULL,
    trackable_type character varying NOT NULL,
    trackable_id bigint NOT NULL,
    author_id bigint,
    action_type smallint NOT NULL,
    note_id bigint,
    details jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    details_html text
);


--
-- Name: merge_request_assignees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_assignees (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    merge_request_id bigint NOT NULL,
    project_id bigint,
    created_at timestamp(6) without time zone
);


--
-- Name: merge_request_assignees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_request_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_request_assignees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_request_assignees_id_seq OWNED BY public.merge_request_assignees.id;


--
-- Name: merge_request_diff_commit_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_diff_commit_users (
    id bigint NOT NULL,
    name text,
    email text,
    organization_id bigint
);


--
-- Name: merge_request_diff_commit_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_request_diff_commit_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_request_diff_commit_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_request_diff_commit_users_id_seq OWNED BY public.merge_request_diff_commit_users.id;


--
-- Name: merge_request_diff_commits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_diff_commits (
    authored_date timestamp(6) without time zone,
    committed_date timestamp(6) without time zone,
    merge_request_diff_id bigint NOT NULL,
    relative_order integer NOT NULL,
    sha character varying,
    message text,
    trailers jsonb DEFAULT '{}'::jsonb,
    commit_author_id bigint,
    committer_id bigint,
    merge_request_commits_metadata_id bigint
);


--
-- Name: merge_request_diff_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_diff_files (
    merge_request_diff_id bigint NOT NULL,
    relative_order integer NOT NULL,
    new_file boolean NOT NULL,
    renamed_file boolean NOT NULL,
    deleted_file boolean NOT NULL,
    too_large boolean NOT NULL,
    a_mode character varying NOT NULL,
    b_mode character varying NOT NULL,
    new_path text NOT NULL,
    old_path text NOT NULL,
    diff text,
    "binary" boolean,
    external_diff_offset integer,
    external_diff_size integer,
    generated boolean,
    encoded_file_path boolean DEFAULT false NOT NULL,
    project_id bigint
);


--
-- Name: merge_request_diffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_diffs (
    id bigint NOT NULL,
    state character varying,
    merge_request_id bigint NOT NULL,
    base_commit_sha character varying,
    real_size character varying,
    head_commit_sha character varying,
    start_commit_sha character varying,
    commits_count integer DEFAULT 0,
    external_diff character varying,
    external_diff_store integer DEFAULT 1,
    stored_externally boolean,
    files_count smallint DEFAULT 0,
    sorted boolean DEFAULT false NOT NULL,
    diff_type smallint DEFAULT 1 NOT NULL,
    patch_id_sha bytea,
    project_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: merge_request_diffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_request_diffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_request_diffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_request_diffs_id_seq OWNED BY public.merge_request_diffs.id;


--
-- Name: merge_request_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_metrics (
    id bigint NOT NULL,
    merge_request_id bigint NOT NULL,
    latest_build_started_at timestamp without time zone,
    latest_build_finished_at timestamp without time zone,
    first_deployed_to_production_at timestamp without time zone,
    merged_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    merged_by_id bigint,
    latest_closed_by_id bigint,
    latest_closed_at timestamp with time zone,
    first_comment_at timestamp with time zone,
    first_commit_at timestamp with time zone,
    last_commit_at timestamp with time zone,
    diff_size integer,
    modified_paths_size integer,
    commits_count integer,
    first_approved_at timestamp with time zone,
    first_reassigned_at timestamp with time zone,
    added_lines integer,
    removed_lines integer,
    target_project_id bigint,
    pipeline_id bigint,
    first_contribution boolean DEFAULT false NOT NULL,
    reviewer_first_assigned_at timestamp with time zone
);


--
-- Name: merge_request_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_request_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_request_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_request_metrics_id_seq OWNED BY public.merge_request_metrics.id;


--
-- Name: merge_request_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_notes (
    id bigint DEFAULT nextval('public.notes_id_seq'::regclass) NOT NULL,
    note text,
    noteable_type character varying NOT NULL,
    noteable_id bigint,
    author_id bigint NOT NULL,
    updated_by_id bigint,
    discussion_id character varying,
    system boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    resolved_at timestamp(6) without time zone,
    resolved_by_id bigint,
    confidential boolean,
    last_edited_at timestamp(6) without time zone,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    type character varying NOT NULL,
    note_html text,
    "position" text,
    original_position text,
    change_position text,
    line_code character varying
);


--
-- Name: merge_request_reviewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_request_reviewers (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    merge_request_id bigint NOT NULL,
    project_id bigint NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: merge_request_reviewers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_request_reviewers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_request_reviewers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_request_reviewers_id_seq OWNED BY public.merge_request_reviewers.id;


--
-- Name: merge_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merge_requests (
    id bigint NOT NULL,
    target_project_id bigint NOT NULL,
    target_branch character varying NOT NULL,
    source_branch character varying NOT NULL,
    source_project_id bigint NOT NULL,
    author_id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    merge_error text,
    merge_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    merge_user_id bigint,
    status integer DEFAULT 1 NOT NULL,
    merge_ref_sha character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    latest_merge_request_diff_id bigint,
    iid integer,
    draft boolean DEFAULT false NOT NULL,
    head_pipeline_id bigint,
    merge_commit_sha character varying,
    merge_jid character varying,
    merge_status character varying DEFAULT 'unchecked'::character varying NOT NULL,
    merge_when_pipeline_succeeds boolean DEFAULT false NOT NULL,
    merged_commit_sha bytea,
    override_requested_changes boolean DEFAULT false NOT NULL,
    prepared_at timestamp with time zone,
    rebase_commit_sha character varying,
    rebase_jid character varying,
    retargeted boolean DEFAULT false NOT NULL,
    squash boolean DEFAULT false NOT NULL,
    squash_commit_sha bytea,
    state_id smallint DEFAULT 1 NOT NULL,
    in_progress_merge_commit_sha character varying,
    description_html text
);


--
-- Name: merge_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merge_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merge_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merge_requests_id_seq OWNED BY public.merge_requests.id;


--
-- Name: namespace_descendants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_descendants (
    namespace_id bigint DEFAULT 0 NOT NULL,
    self_and_descendant_group_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    all_project_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    traversal_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    outdated_at timestamp with time zone,
    calculated_at timestamp with time zone,
    all_active_project_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    all_unarchived_project_ids bigint[] DEFAULT '{}'::bigint[]
);


--
-- Name: namespace_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_settings (
    id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    default_branch_name text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    squash_enabled boolean DEFAULT true NOT NULL
);


--
-- Name: namespace_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.namespace_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: namespace_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.namespace_settings_id_seq OWNED BY public.namespace_settings.id;


--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespaces (
    id bigint NOT NULL,
    parent_id bigint,
    name character varying NOT NULL,
    path character varying NOT NULL,
    type character varying NOT NULL,
    visibility_level integer DEFAULT 0 NOT NULL,
    traversal_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    creator_id integer
);


--
-- Name: namespaces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.namespaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: namespaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.namespaces_id_seq OWNED BY public.namespaces.id;


--
-- Name: note_diff_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_diff_files (
    id bigint NOT NULL,
    diff text NOT NULL,
    new_file boolean NOT NULL,
    renamed_file boolean NOT NULL,
    deleted_file boolean NOT NULL,
    a_mode character varying NOT NULL,
    b_mode character varying NOT NULL,
    new_path text NOT NULL,
    old_path text NOT NULL,
    diff_note_id bigint NOT NULL
);


--
-- Name: note_diff_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.note_diff_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: note_diff_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.note_diff_files_id_seq OWNED BY public.note_diff_files.id;


--
-- Name: notification_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    source_type character varying,
    source_id bigint,
    level integer DEFAULT 0 NOT NULL,
    new_note boolean,
    new_issue boolean,
    reopen_issue boolean,
    close_issue boolean,
    reassign_issue boolean,
    new_merge_request boolean,
    close_merge_request boolean,
    reassign_merge_request boolean,
    merge_merge_request boolean,
    change_reviewer_merge_request boolean,
    reopen_merge_request boolean,
    failed_pipeline boolean,
    fixed_pipeline boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notification_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_settings_id_seq OWNED BY public.notification_settings.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id bigint NOT NULL,
    resource_owner_id bigint,
    application_id bigint NOT NULL,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    scopes character varying,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id bigint NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    owner_id bigint,
    owner_type character varying,
    trusted boolean DEFAULT false NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    expire_access_tokens boolean DEFAULT false NOT NULL,
    ropc_enabled boolean DEFAULT true NOT NULL,
    dynamic boolean DEFAULT false NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: personal_access_token_last_used_ips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_access_token_last_used_ips (
    id bigint NOT NULL,
    personal_access_token_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    ip_address inet
);


--
-- Name: personal_access_token_last_used_ips_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_access_token_last_used_ips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_access_token_last_used_ips_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_access_token_last_used_ips_id_seq OWNED BY public.personal_access_token_last_used_ips.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying NOT NULL,
    revoked boolean DEFAULT false,
    expires_at date,
    scopes character varying DEFAULT '--- []\n'::character varying NOT NULL,
    token_digest character varying,
    last_used_at timestamp(6) without time zone,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: plan_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_limits (
    id bigint NOT NULL,
    plan_id bigint NOT NULL,
    ci_pipeline_size integer DEFAULT 0 NOT NULL,
    ci_active_jobs integer DEFAULT 0 NOT NULL,
    project_hooks integer DEFAULT 100 NOT NULL,
    group_hooks integer DEFAULT 50 NOT NULL,
    ci_project_subscriptions integer DEFAULT 2 NOT NULL,
    ci_pipeline_schedules integer DEFAULT 10 NOT NULL,
    offset_pagination_limit integer DEFAULT 50000 NOT NULL,
    ci_instance_level_variables integer DEFAULT 25 NOT NULL,
    storage_size_limit integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_lsif integer DEFAULT 200 NOT NULL,
    ci_max_artifact_size_archive integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_metadata integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_trace integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_junit integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_sast integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_dependency_scanning integer DEFAULT 350 NOT NULL,
    ci_max_artifact_size_container_scanning integer DEFAULT 150 NOT NULL,
    ci_max_artifact_size_dast integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_codequality integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_license_management integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_license_scanning integer DEFAULT 100 NOT NULL,
    ci_max_artifact_size_performance integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_metrics integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_metrics_referee integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_network_referee integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_dotenv integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_cobertura integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_terraform integer DEFAULT 5 NOT NULL,
    ci_max_artifact_size_accessibility integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_cluster_applications integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_secret_detection integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_requirements integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_coverage_fuzzing integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_browser_performance integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_load_performance integer DEFAULT 0 NOT NULL,
    ci_needs_size_limit integer DEFAULT 50 NOT NULL,
    conan_max_file_size bigint DEFAULT '3221225472'::bigint NOT NULL,
    maven_max_file_size bigint DEFAULT '3221225472'::bigint NOT NULL,
    npm_max_file_size bigint DEFAULT 524288000 NOT NULL,
    nuget_max_file_size bigint DEFAULT 524288000 NOT NULL,
    pypi_max_file_size bigint DEFAULT '3221225472'::bigint NOT NULL,
    generic_packages_max_file_size bigint DEFAULT '5368709120'::bigint NOT NULL,
    golang_max_file_size bigint DEFAULT 104857600 NOT NULL,
    debian_max_file_size bigint DEFAULT '3221225472'::bigint NOT NULL,
    project_feature_flags integer DEFAULT 200 NOT NULL,
    ci_max_artifact_size_api_fuzzing integer DEFAULT 0 NOT NULL,
    ci_pipeline_deployments integer DEFAULT 500 NOT NULL,
    pull_mirror_interval_seconds integer DEFAULT 300 NOT NULL,
    daily_invites integer DEFAULT 0 NOT NULL,
    rubygems_max_file_size bigint DEFAULT '3221225472'::bigint NOT NULL,
    terraform_module_max_file_size bigint DEFAULT 1073741824 NOT NULL,
    helm_max_file_size bigint DEFAULT 5242880 NOT NULL,
    ci_registered_group_runners integer DEFAULT 1000 NOT NULL,
    ci_registered_project_runners integer DEFAULT 1000 NOT NULL,
    ci_daily_pipeline_schedule_triggers integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_running_container_scanning integer DEFAULT 0 NOT NULL,
    ci_max_artifact_size_cluster_image_scanning integer DEFAULT 0 NOT NULL,
    ci_jobs_trace_size_limit integer DEFAULT 100 NOT NULL,
    pages_file_entries integer DEFAULT 200000 NOT NULL,
    dast_profile_schedules integer DEFAULT 1 NOT NULL,
    external_audit_event_destinations integer DEFAULT 5 NOT NULL,
    dotenv_variables integer DEFAULT 20 NOT NULL,
    dotenv_size integer DEFAULT 5120 NOT NULL,
    pipeline_triggers integer DEFAULT 25000 NOT NULL,
    project_ci_secure_files integer DEFAULT 100 NOT NULL,
    repository_size bigint,
    security_policy_scan_execution_schedules integer DEFAULT 0 NOT NULL,
    web_hook_calls_mid integer DEFAULT 0 NOT NULL,
    web_hook_calls_low integer DEFAULT 0 NOT NULL,
    project_ci_variables integer DEFAULT 8000 NOT NULL,
    group_ci_variables integer DEFAULT 30000 NOT NULL,
    ci_max_artifact_size_cyclonedx integer DEFAULT 1 NOT NULL,
    rpm_max_file_size bigint DEFAULT '5368709120'::bigint NOT NULL,
    ci_max_artifact_size_requirements_v2 integer DEFAULT 0 NOT NULL,
    pipeline_hierarchy_size integer DEFAULT 1000 NOT NULL,
    enforcement_limit integer DEFAULT 0 NOT NULL,
    notification_limit integer DEFAULT 0 NOT NULL,
    dashboard_limit_enabled_at timestamp(6) without time zone,
    web_hook_calls integer DEFAULT 0 NOT NULL,
    project_access_token_limit integer DEFAULT 0 NOT NULL,
    google_cloud_logging_configurations integer DEFAULT 5 NOT NULL,
    ml_model_max_file_size bigint DEFAULT '10737418240'::bigint NOT NULL,
    limits_history jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ci_max_artifact_size_annotations integer DEFAULT 0 NOT NULL,
    ci_job_annotations_size integer DEFAULT 81920 NOT NULL,
    ci_job_annotations_num integer DEFAULT 20 NOT NULL,
    file_size_limit_mb double precision DEFAULT 100.0 NOT NULL,
    audit_events_amazon_s3_configurations integer DEFAULT 5 NOT NULL,
    ci_max_artifact_size_repository_xray bigint DEFAULT 1073741824 NOT NULL,
    active_versioned_pages_deployments_limit_by_namespace integer DEFAULT 1000 NOT NULL,
    ci_max_artifact_size_jacoco bigint DEFAULT 0 NOT NULL,
    import_placeholder_user_limit_tier_1 integer DEFAULT 0 NOT NULL,
    import_placeholder_user_limit_tier_2 integer DEFAULT 0 NOT NULL,
    import_placeholder_user_limit_tier_3 integer DEFAULT 0 NOT NULL,
    import_placeholder_user_limit_tier_4 integer DEFAULT 0 NOT NULL
);


--
-- Name: plan_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plan_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plan_limits_id_seq OWNED BY public.plan_limits.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying,
    title character varying
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: project_ci_cd_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_ci_cd_settings (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    group_runners_enabled boolean DEFAULT true NOT NULL,
    merge_pipelines_enabled boolean,
    default_git_depth integer,
    forward_deployment_enabled boolean,
    merge_trains_enabled boolean DEFAULT false,
    auto_rollback_enabled boolean DEFAULT false NOT NULL,
    keep_latest_artifact boolean DEFAULT true NOT NULL,
    restrict_user_defined_variables boolean DEFAULT false NOT NULL,
    job_token_scope_enabled boolean DEFAULT false NOT NULL,
    runner_token_expiration_interval integer,
    separated_caches boolean DEFAULT true NOT NULL,
    allow_fork_pipelines_to_run_in_parent_project boolean DEFAULT true NOT NULL,
    inbound_job_token_scope_enabled boolean DEFAULT true NOT NULL,
    forward_deployment_rollback_allowed boolean DEFAULT true NOT NULL,
    merge_trains_skip_train_allowed boolean DEFAULT false NOT NULL,
    restrict_pipeline_cancellation_role integer DEFAULT 0 NOT NULL,
    pipeline_variables_minimum_override_role integer DEFAULT 3 NOT NULL,
    push_repository_for_job_token_allowed boolean DEFAULT false NOT NULL,
    id_token_sub_claim_components character varying[] DEFAULT '{project_path,ref_type,ref}'::character varying[] NOT NULL,
    delete_pipelines_in_seconds integer,
    allow_composite_identities_to_run_pipelines boolean DEFAULT false NOT NULL
);


--
-- Name: project_ci_cd_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_ci_cd_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_ci_cd_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_ci_cd_settings_id_seq OWNED BY public.project_ci_cd_settings.id;


--
-- Name: project_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_features (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    merge_requests_access_level integer,
    issues_access_level integer,
    wiki_access_level integer,
    snippets_access_level integer DEFAULT 20 NOT NULL,
    builds_access_level integer,
    repository_access_level integer DEFAULT 20 NOT NULL,
    pages_access_level integer NOT NULL,
    forking_access_level integer,
    metrics_dashboard_access_level integer,
    requirements_access_level integer DEFAULT 20 NOT NULL,
    operations_access_level integer DEFAULT 20 NOT NULL,
    analytics_access_level integer DEFAULT 20 NOT NULL,
    security_and_compliance_access_level integer DEFAULT 10 NOT NULL,
    container_registry_access_level integer DEFAULT 0 NOT NULL,
    package_registry_access_level integer DEFAULT 0 NOT NULL,
    monitor_access_level integer DEFAULT 20 NOT NULL,
    infrastructure_access_level integer DEFAULT 20 NOT NULL,
    feature_flags_access_level integer DEFAULT 20 NOT NULL,
    environments_access_level integer DEFAULT 20 NOT NULL,
    releases_access_level integer DEFAULT 20 NOT NULL,
    model_experiments_access_level integer DEFAULT 20 NOT NULL,
    model_registry_access_level integer DEFAULT 20 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: project_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_features_id_seq OWNED BY public.project_features.id;


--
-- Name: project_pipeline_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_pipeline_settings (
    id bigint NOT NULL,
    auto_cancel_pending_pipelines boolean DEFAULT true,
    ci_config_path character varying,
    build_allow_git_fetch boolean DEFAULT true,
    build_timeout integer DEFAULT 3600,
    project_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: project_pipeline_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_pipeline_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_pipeline_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_pipeline_settings_id_seq OWNED BY public.project_pipeline_settings.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    name character varying NOT NULL,
    path character varying NOT NULL,
    description text,
    namespace_id bigint NOT NULL,
    avatar character varying,
    repository_storage character varying DEFAULT 'default'::character varying NOT NULL,
    lfs_enabled boolean DEFAULT false NOT NULL,
    storage_version smallint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    runners_token character varying,
    runners_token_encrypted character varying,
    build_timeout integer DEFAULT 3600 NOT NULL,
    jobs_cache_index integer,
    workflows character varying DEFAULT 'workflow::'::character varying,
    public_jobs boolean DEFAULT true NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: protected_refs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protected_refs (
    id bigint NOT NULL,
    type character varying NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    access_level integer DEFAULT 30 NOT NULL,
    allow_push boolean DEFAULT false NOT NULL,
    allow_force_push boolean DEFAULT false NOT NULL,
    allow_merge_to boolean DEFAULT false NOT NULL,
    namespace_id bigint NOT NULL
);


--
-- Name: protected_refs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.protected_refs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protected_refs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.protected_refs_id_seq OWNED BY public.protected_refs.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id bigint NOT NULL,
    author_id bigint NOT NULL,
    merge_request_id bigint NOT NULL,
    project_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: routes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.routes (
    id bigint NOT NULL,
    path character varying NOT NULL,
    name character varying,
    namespace_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: routes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: routes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.routes_id_seq OWNED BY public.routes.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    name character varying,
    taggings_count integer DEFAULT 0
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uploads (
    id bigint NOT NULL,
    size bigint NOT NULL,
    model_type character varying NOT NULL,
    model_id bigint NOT NULL,
    uploaded_by_user_id bigint,
    namespace_id bigint,
    store integer DEFAULT 1 NOT NULL,
    version integer DEFAULT 1,
    path text NOT NULL,
    checksum text,
    uploader text NOT NULL,
    mount_point text,
    secret text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    confirmation_sent_at timestamp(6) without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    username character varying NOT NULL,
    name character varying NOT NULL,
    mobile character varying,
    avatar character varying,
    user_type integer DEFAULT 0,
    admin boolean DEFAULT false NOT NULL,
    composite_identity_enforced boolean DEFAULT false NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    password_automatically_set boolean DEFAULT false,
    password_expires_at timestamp(6) without time zone,
    timezone character varying,
    preferred_language character varying DEFAULT 'en'::character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
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
-- Name: web_hooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_hooks (
    id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    type character varying DEFAULT 'ProjectHook'::character varying,
    push_events boolean DEFAULT true NOT NULL,
    tag_push_events boolean DEFAULT false,
    encrypted_url character varying,
    encrypted_url_iv character varying,
    name text,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: web_hooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_hooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_hooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_hooks_id_seq OWNED BY public.web_hooks.id;


--
-- Name: work_item_assignees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_item_assignees (
    id bigint NOT NULL,
    work_item_id bigint NOT NULL,
    assignee_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: work_item_assignees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_item_assignees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_item_assignees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_item_assignees_id_seq OWNED BY public.work_item_assignees.id;


--
-- Name: work_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_items (
    id bigint NOT NULL,
    type character varying NOT NULL,
    title character varying,
    author_id bigint,
    description text,
    iid integer,
    updated_by_id bigint,
    confidential boolean DEFAULT false NOT NULL,
    due_date date,
    state_id smallint DEFAULT 1 NOT NULL,
    closed_at timestamp without time zone,
    closed_by_id bigint,
    parent_id bigint,
    namespace_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description_html text
);


--
-- Name: work_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_items_id_seq OWNED BY public.work_items.id;


--
-- Name: epic_activities; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ATTACH PARTITION public.epic_activities FOR VALUES IN ('Epic');


--
-- Name: epic_notes; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ATTACH PARTITION public.epic_notes FOR VALUES IN ('Epic');


--
-- Name: issue_activities; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ATTACH PARTITION public.issue_activities FOR VALUES IN ('Issue');


--
-- Name: issue_notes; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ATTACH PARTITION public.issue_notes FOR VALUES IN ('Issue');


--
-- Name: merge_request_activities; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ATTACH PARTITION public.merge_request_activities FOR VALUES IN ('MergeRequest');


--
-- Name: merge_request_notes; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ATTACH PARTITION public.merge_request_notes FOR VALUES IN ('MergeRequest');


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: application_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_settings ALTER COLUMN id SET DEFAULT nextval('public.application_settings_id_seq'::regclass);


--
-- Name: board_stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.board_stages ALTER COLUMN id SET DEFAULT nextval('public.board_stages_id_seq'::regclass);


--
-- Name: boards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards ALTER COLUMN id SET DEFAULT nextval('public.boards_id_seq'::regclass);


--
-- Name: ci_build_needs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_needs ALTER COLUMN id SET DEFAULT nextval('public.ci_build_needs_id_seq'::regclass);


--
-- Name: ci_build_pending_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_pending_states ALTER COLUMN id SET DEFAULT nextval('public.ci_build_pending_states_id_seq'::regclass);


--
-- Name: ci_build_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_tags ALTER COLUMN id SET DEFAULT nextval('public.ci_build_tags_id_seq'::regclass);


--
-- Name: ci_build_trace_chunks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_trace_chunks ALTER COLUMN id SET DEFAULT nextval('public.ci_build_trace_chunks_id_seq'::regclass);


--
-- Name: ci_build_trace_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_trace_metadata ALTER COLUMN id SET DEFAULT nextval('public.ci_build_trace_metadata_id_seq'::regclass);


--
-- Name: ci_builds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_id_seq'::regclass);


--
-- Name: ci_builds_execution_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_execution_configs ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_execution_configs_id_seq'::regclass);


--
-- Name: ci_builds_metadata id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_metadata ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_metadata_id_seq'::regclass);


--
-- Name: ci_builds_runner_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_runner_session ALTER COLUMN id SET DEFAULT nextval('public.ci_builds_runner_session_id_seq'::regclass);


--
-- Name: ci_instance_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_instance_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_instance_variables_id_seq'::regclass);


--
-- Name: ci_job_artifacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_job_artifacts ALTER COLUMN id SET DEFAULT nextval('public.ci_job_artifacts_id_seq'::regclass);


--
-- Name: ci_job_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_job_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_job_variables_id_seq'::regclass);


--
-- Name: ci_pending_builds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pending_builds ALTER COLUMN id SET DEFAULT nextval('public.ci_pending_builds_id_seq'::regclass);


--
-- Name: ci_pipeline_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipeline_messages ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_messages_id_seq'::regclass);


--
-- Name: ci_pipeline_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipeline_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_pipeline_variables_id_seq'::regclass);


--
-- Name: ci_pipelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipelines ALTER COLUMN id SET DEFAULT nextval('public.ci_pipelines_id_seq'::regclass);


--
-- Name: ci_refs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_refs ALTER COLUMN id SET DEFAULT nextval('public.ci_refs_id_seq'::regclass);


--
-- Name: ci_runner_taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runner_taggings ALTER COLUMN id SET DEFAULT nextval('public.ci_runner_taggings_id_seq'::regclass);


--
-- Name: ci_runners id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runners ALTER COLUMN id SET DEFAULT nextval('public.ci_runners_id_seq'::regclass);


--
-- Name: ci_running_builds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_running_builds ALTER COLUMN id SET DEFAULT nextval('public.ci_running_builds_id_seq'::regclass);


--
-- Name: ci_sources_pipelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_sources_pipelines ALTER COLUMN id SET DEFAULT nextval('public.ci_sources_pipelines_id_seq'::regclass);


--
-- Name: ci_stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_stages ALTER COLUMN id SET DEFAULT nextval('public.ci_stages_id_seq'::regclass);


--
-- Name: ci_triggers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_triggers ALTER COLUMN id SET DEFAULT nextval('public.ci_triggers_id_seq'::regclass);


--
-- Name: ci_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_variables_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: internal_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ids ALTER COLUMN id SET DEFAULT nextval('public.internal_ids_id_seq'::regclass);


--
-- Name: item_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_links ALTER COLUMN id SET DEFAULT nextval('public.item_links_id_seq'::regclass);


--
-- Name: keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keys ALTER COLUMN id SET DEFAULT nextval('public.keys_id_seq'::regclass);


--
-- Name: label_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_links ALTER COLUMN id SET DEFAULT nextval('public.label_links_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members ALTER COLUMN id SET DEFAULT nextval('public.members_id_seq'::regclass);


--
-- Name: merge_request_assignees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_assignees ALTER COLUMN id SET DEFAULT nextval('public.merge_request_assignees_id_seq'::regclass);


--
-- Name: merge_request_diff_commit_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diff_commit_users ALTER COLUMN id SET DEFAULT nextval('public.merge_request_diff_commit_users_id_seq'::regclass);


--
-- Name: merge_request_diffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diffs ALTER COLUMN id SET DEFAULT nextval('public.merge_request_diffs_id_seq'::regclass);


--
-- Name: merge_request_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_metrics ALTER COLUMN id SET DEFAULT nextval('public.merge_request_metrics_id_seq'::regclass);


--
-- Name: merge_request_reviewers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_reviewers ALTER COLUMN id SET DEFAULT nextval('public.merge_request_reviewers_id_seq'::regclass);


--
-- Name: merge_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_requests ALTER COLUMN id SET DEFAULT nextval('public.merge_requests_id_seq'::regclass);


--
-- Name: namespace_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_settings ALTER COLUMN id SET DEFAULT nextval('public.namespace_settings_id_seq'::regclass);


--
-- Name: namespaces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces ALTER COLUMN id SET DEFAULT nextval('public.namespaces_id_seq'::regclass);


--
-- Name: note_diff_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_diff_files ALTER COLUMN id SET DEFAULT nextval('public.note_diff_files_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: notification_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings ALTER COLUMN id SET DEFAULT nextval('public.notification_settings_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: personal_access_token_last_used_ips id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_token_last_used_ips ALTER COLUMN id SET DEFAULT nextval('public.personal_access_token_last_used_ips_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: plan_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_limits ALTER COLUMN id SET DEFAULT nextval('public.plan_limits_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: project_ci_cd_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_ci_cd_settings ALTER COLUMN id SET DEFAULT nextval('public.project_ci_cd_settings_id_seq'::regclass);


--
-- Name: project_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_features ALTER COLUMN id SET DEFAULT nextval('public.project_features_id_seq'::regclass);


--
-- Name: project_pipeline_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pipeline_settings ALTER COLUMN id SET DEFAULT nextval('public.project_pipeline_settings_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: protected_refs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_refs ALTER COLUMN id SET DEFAULT nextval('public.protected_refs_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: routes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes ALTER COLUMN id SET DEFAULT nextval('public.routes_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: web_hooks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_hooks ALTER COLUMN id SET DEFAULT nextval('public.web_hooks_id_seq'::regclass);


--
-- Name: work_item_assignees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_item_assignees ALTER COLUMN id SET DEFAULT nextval('public.work_item_assignees_id_seq'::regclass);


--
-- Name: work_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items ALTER COLUMN id SET DEFAULT nextval('public.work_items_id_seq'::regclass);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id, trackable_type);


--
-- Name: application_settings application_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_settings
    ADD CONSTRAINT application_settings_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: board_stages board_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.board_stages
    ADD CONSTRAINT board_stages_pkey PRIMARY KEY (id);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: ci_build_needs ci_build_needs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_needs
    ADD CONSTRAINT ci_build_needs_pkey PRIMARY KEY (id);


--
-- Name: ci_build_pending_states ci_build_pending_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_pending_states
    ADD CONSTRAINT ci_build_pending_states_pkey PRIMARY KEY (id);


--
-- Name: ci_build_sources ci_build_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_sources
    ADD CONSTRAINT ci_build_sources_pkey PRIMARY KEY (build_id);


--
-- Name: ci_build_tags ci_build_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_tags
    ADD CONSTRAINT ci_build_tags_pkey PRIMARY KEY (id);


--
-- Name: ci_build_trace_chunks ci_build_trace_chunks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_trace_chunks
    ADD CONSTRAINT ci_build_trace_chunks_pkey PRIMARY KEY (id);


--
-- Name: ci_build_trace_metadata ci_build_trace_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_build_trace_metadata
    ADD CONSTRAINT ci_build_trace_metadata_pkey PRIMARY KEY (id);


--
-- Name: ci_builds_execution_configs ci_builds_execution_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_execution_configs
    ADD CONSTRAINT ci_builds_execution_configs_pkey PRIMARY KEY (id);


--
-- Name: ci_builds_metadata ci_builds_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_metadata
    ADD CONSTRAINT ci_builds_metadata_pkey PRIMARY KEY (id);


--
-- Name: ci_builds ci_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds
    ADD CONSTRAINT ci_builds_pkey PRIMARY KEY (id);


--
-- Name: ci_builds_runner_session ci_builds_runner_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_builds_runner_session
    ADD CONSTRAINT ci_builds_runner_session_pkey PRIMARY KEY (id);


--
-- Name: ci_instance_variables ci_instance_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_instance_variables
    ADD CONSTRAINT ci_instance_variables_pkey PRIMARY KEY (id);


--
-- Name: ci_job_artifacts ci_job_artifacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_job_artifacts
    ADD CONSTRAINT ci_job_artifacts_pkey PRIMARY KEY (id);


--
-- Name: ci_job_variables ci_job_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_job_variables
    ADD CONSTRAINT ci_job_variables_pkey PRIMARY KEY (id);


--
-- Name: ci_pending_builds ci_pending_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pending_builds
    ADD CONSTRAINT ci_pending_builds_pkey PRIMARY KEY (id);


--
-- Name: ci_pipeline_messages ci_pipeline_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipeline_messages
    ADD CONSTRAINT ci_pipeline_messages_pkey PRIMARY KEY (id);


--
-- Name: ci_pipeline_metadata ci_pipeline_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipeline_metadata
    ADD CONSTRAINT ci_pipeline_metadata_pkey PRIMARY KEY (pipeline_id);


--
-- Name: ci_pipeline_variables ci_pipeline_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipeline_variables
    ADD CONSTRAINT ci_pipeline_variables_pkey PRIMARY KEY (id);


--
-- Name: ci_pipelines_configs ci_pipelines_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipelines_configs
    ADD CONSTRAINT ci_pipelines_configs_pkey PRIMARY KEY (pipeline_id);


--
-- Name: ci_pipelines ci_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pipelines
    ADD CONSTRAINT ci_pipelines_pkey PRIMARY KEY (id);


--
-- Name: ci_refs ci_refs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_refs
    ADD CONSTRAINT ci_refs_pkey PRIMARY KEY (id);


--
-- Name: ci_runner_machine_builds ci_runner_machine_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runner_machine_builds
    ADD CONSTRAINT ci_runner_machine_builds_pkey PRIMARY KEY (build_id);


--
-- Name: ci_runner_machines ci_runner_machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runner_machines
    ADD CONSTRAINT ci_runner_machines_pkey PRIMARY KEY (id);


--
-- Name: ci_runner_taggings ci_runner_taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runner_taggings
    ADD CONSTRAINT ci_runner_taggings_pkey PRIMARY KEY (id);


--
-- Name: ci_runner_versions ci_runner_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runner_versions
    ADD CONSTRAINT ci_runner_versions_pkey PRIMARY KEY (version);


--
-- Name: ci_runners ci_runners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_runners
    ADD CONSTRAINT ci_runners_pkey PRIMARY KEY (id);


--
-- Name: ci_running_builds ci_running_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_running_builds
    ADD CONSTRAINT ci_running_builds_pkey PRIMARY KEY (id);


--
-- Name: ci_sources_pipelines ci_sources_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_sources_pipelines
    ADD CONSTRAINT ci_sources_pipelines_pkey PRIMARY KEY (id);


--
-- Name: ci_stages ci_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_stages
    ADD CONSTRAINT ci_stages_pkey PRIMARY KEY (id);


--
-- Name: ci_triggers ci_triggers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_triggers
    ADD CONSTRAINT ci_triggers_pkey PRIMARY KEY (id);


--
-- Name: ci_variables ci_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_variables
    ADD CONSTRAINT ci_variables_pkey PRIMARY KEY (id);


--
-- Name: epic_activities epic_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_activities
    ADD CONSTRAINT epic_activities_pkey PRIMARY KEY (id, trackable_type);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id, noteable_type);


--
-- Name: epic_notes epic_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_notes
    ADD CONSTRAINT epic_notes_pkey PRIMARY KEY (id, noteable_type);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: internal_ids internal_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ids
    ADD CONSTRAINT internal_ids_pkey PRIMARY KEY (id);


--
-- Name: issue_activities issue_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_activities
    ADD CONSTRAINT issue_activities_pkey PRIMARY KEY (id, trackable_type);


--
-- Name: issue_notes issue_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_notes
    ADD CONSTRAINT issue_notes_pkey PRIMARY KEY (id, noteable_type);


--
-- Name: item_links item_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_links
    ADD CONSTRAINT item_links_pkey PRIMARY KEY (id);


--
-- Name: keys keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);


--
-- Name: label_links label_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_links
    ADD CONSTRAINT label_links_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: merge_request_activities merge_request_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_activities
    ADD CONSTRAINT merge_request_activities_pkey PRIMARY KEY (id, trackable_type);


--
-- Name: merge_request_assignees merge_request_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_assignees
    ADD CONSTRAINT merge_request_assignees_pkey PRIMARY KEY (id);


--
-- Name: merge_request_diff_commit_users merge_request_diff_commit_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diff_commit_users
    ADD CONSTRAINT merge_request_diff_commit_users_pkey PRIMARY KEY (id);


--
-- Name: merge_request_diff_commits merge_request_diff_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diff_commits
    ADD CONSTRAINT merge_request_diff_commits_pkey PRIMARY KEY (merge_request_diff_id, relative_order);


--
-- Name: merge_request_diff_files merge_request_diff_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diff_files
    ADD CONSTRAINT merge_request_diff_files_pkey PRIMARY KEY (merge_request_diff_id, relative_order);


--
-- Name: merge_request_diffs merge_request_diffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_diffs
    ADD CONSTRAINT merge_request_diffs_pkey PRIMARY KEY (id);


--
-- Name: merge_request_metrics merge_request_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_metrics
    ADD CONSTRAINT merge_request_metrics_pkey PRIMARY KEY (id);


--
-- Name: merge_request_notes merge_request_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_notes
    ADD CONSTRAINT merge_request_notes_pkey PRIMARY KEY (id, noteable_type);


--
-- Name: merge_request_reviewers merge_request_reviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_request_reviewers
    ADD CONSTRAINT merge_request_reviewers_pkey PRIMARY KEY (id);


--
-- Name: merge_requests merge_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merge_requests
    ADD CONSTRAINT merge_requests_pkey PRIMARY KEY (id);


--
-- Name: namespace_descendants namespace_descendants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_descendants
    ADD CONSTRAINT namespace_descendants_pkey PRIMARY KEY (namespace_id);


--
-- Name: namespace_settings namespace_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_settings
    ADD CONSTRAINT namespace_settings_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: note_diff_files note_diff_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_diff_files
    ADD CONSTRAINT note_diff_files_pkey PRIMARY KEY (id);


--
-- Name: notification_settings notification_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_settings
    ADD CONSTRAINT notification_settings_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: personal_access_token_last_used_ips personal_access_token_last_used_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_token_last_used_ips
    ADD CONSTRAINT personal_access_token_last_used_ips_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: plan_limits plan_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_limits
    ADD CONSTRAINT plan_limits_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: project_ci_cd_settings project_ci_cd_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_ci_cd_settings
    ADD CONSTRAINT project_ci_cd_settings_pkey PRIMARY KEY (id);


--
-- Name: project_features project_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_features
    ADD CONSTRAINT project_features_pkey PRIMARY KEY (id);


--
-- Name: project_pipeline_settings project_pipeline_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pipeline_settings
    ADD CONSTRAINT project_pipeline_settings_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: protected_refs protected_refs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protected_refs
    ADD CONSTRAINT protected_refs_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: web_hooks web_hooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_hooks
    ADD CONSTRAINT web_hooks_pkey PRIMARY KEY (id);


--
-- Name: work_item_assignees work_item_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_item_assignees
    ADD CONSTRAINT work_item_assignees_pkey PRIMARY KEY (id);


--
-- Name: work_items work_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_items
    ADD CONSTRAINT work_items_pkey PRIMARY KEY (id);


--
-- Name: index_activities_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_author_id ON ONLY public.activities USING btree (author_id);


--
-- Name: epic_activities_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_activities_author_id_idx ON public.epic_activities USING btree (author_id);


--
-- Name: index_activities_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_created_at ON ONLY public.activities USING btree (created_at);


--
-- Name: epic_activities_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_activities_created_at_idx ON public.epic_activities USING btree (created_at);


--
-- Name: index_activities_on_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_note_id ON ONLY public.activities USING btree (note_id);


--
-- Name: epic_activities_note_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_activities_note_id_idx ON public.epic_activities USING btree (note_id);


--
-- Name: index_activities_on_trackable_type_and_trackable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_trackable_type_and_trackable_id ON ONLY public.activities USING btree (trackable_type, trackable_id);


--
-- Name: epic_activities_trackable_type_trackable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_activities_trackable_type_trackable_id_idx ON public.epic_activities USING btree (trackable_type, trackable_id);


--
-- Name: index_notes_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_author_id ON ONLY public.notes USING btree (author_id);


--
-- Name: epic_notes_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_author_id_idx ON public.epic_notes USING btree (author_id);


--
-- Name: index_notes_on_confidential; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_confidential ON ONLY public.notes USING btree (confidential);


--
-- Name: epic_notes_confidential_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_confidential_idx ON public.epic_notes USING btree (confidential);


--
-- Name: index_notes_on_discussion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_discussion_id ON ONLY public.notes USING btree (discussion_id);


--
-- Name: epic_notes_discussion_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_discussion_id_idx ON public.epic_notes USING btree (discussion_id);


--
-- Name: index_notes_on_internal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_internal ON ONLY public.notes USING btree (internal);


--
-- Name: epic_notes_internal_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_internal_idx ON public.epic_notes USING btree (internal);


--
-- Name: index_notes_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_namespace_id ON ONLY public.notes USING btree (namespace_id);


--
-- Name: epic_notes_namespace_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_namespace_id_idx ON public.epic_notes USING btree (namespace_id);


--
-- Name: index_notes_on_noteable_type_and_noteable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_noteable_type_and_noteable_id ON ONLY public.notes USING btree (noteable_type, noteable_id);


--
-- Name: epic_notes_noteable_type_noteable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_noteable_type_noteable_id_idx ON public.epic_notes USING btree (noteable_type, noteable_id);


--
-- Name: index_notes_on_resolved_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_resolved_at ON ONLY public.notes USING btree (resolved_at);


--
-- Name: epic_notes_resolved_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_resolved_at_idx ON public.epic_notes USING btree (resolved_at);


--
-- Name: index_notes_on_resolved_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_resolved_by_id ON ONLY public.notes USING btree (resolved_by_id);


--
-- Name: epic_notes_resolved_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_resolved_by_id_idx ON public.epic_notes USING btree (resolved_by_id);


--
-- Name: index_notes_on_system; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_system ON ONLY public.notes USING btree (system);


--
-- Name: epic_notes_system_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_system_idx ON public.epic_notes USING btree (system);


--
-- Name: index_notes_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_type ON ONLY public.notes USING btree (type);


--
-- Name: epic_notes_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_type_idx ON public.epic_notes USING btree (type);


--
-- Name: index_notes_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_updated_by_id ON ONLY public.notes USING btree (updated_by_id);


--
-- Name: epic_notes_updated_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX epic_notes_updated_by_id_idx ON public.epic_notes USING btree (updated_by_id);


--
-- Name: idx_on_label_id_labelable_id_labelable_type_ba485d0134; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_label_id_labelable_id_labelable_type_ba485d0134 ON public.label_links USING btree (label_id, labelable_id, labelable_type);


--
-- Name: idx_on_merge_request_commits_metadata_id_86032d633b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_merge_request_commits_metadata_id_86032d633b ON public.merge_request_diff_commits USING btree (merge_request_commits_metadata_id) WHERE (merge_request_commits_metadata_id IS NOT NULL);


--
-- Name: idx_on_model_id_model_type_uploader_created_at_085f046dbe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_model_id_model_type_uploader_created_at_085f046dbe ON public.uploads USING btree (model_id, model_type, uploader, created_at);


--
-- Name: idx_on_namespace_id_key_environment_scope_c85a9bce13; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_namespace_id_key_environment_scope_c85a9bce13 ON public.ci_variables USING btree (namespace_id, key, environment_scope);


--
-- Name: idx_on_organization_id_name_email_0254cd9454; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_organization_id_name_email_0254cd9454 ON public.merge_request_diff_commit_users USING btree (organization_id, name, email);


--
-- Name: idx_on_personal_access_token_id_bf77e61c9c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_personal_access_token_id_bf77e61c9c ON public.personal_access_token_last_used_ips USING btree (personal_access_token_id);


--
-- Name: idx_on_resource_owner_id_application_id_created_at_971a753b2e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_resource_owner_id_application_id_created_at_971a753b2e ON public.oauth_access_tokens USING btree (resource_owner_id, application_id, created_at) WHERE (revoked_at IS NULL);


--
-- Name: idx_on_resource_owner_id_application_id_created_at_994f2a8ec2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_resource_owner_id_application_id_created_at_994f2a8ec2 ON public.oauth_access_grants USING btree (resource_owner_id, application_id, created_at);


--
-- Name: idx_on_runner_id_runner_type_system_xid_b7799f140b; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_runner_id_runner_type_system_xid_b7799f140b ON public.ci_runner_machines USING btree (runner_id, runner_type, system_xid);


--
-- Name: idx_on_runner_type_runner_owner_namespace_xid_runne_c7da599c50; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_runner_type_runner_owner_namespace_xid_runne_c7da599c50 ON public.ci_running_builds USING btree (runner_type, runner_owner_namespace_xid, runner_id);


--
-- Name: idx_on_tag_id_runner_id_runner_type_5c956d0365; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_tag_id_runner_id_runner_type_5c956d0365 ON public.ci_runner_taggings USING btree (tag_id, runner_id, runner_type);


--
-- Name: idx_on_target_project_id_merged_commit_sha_f498e76f62; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_target_project_id_merged_commit_sha_f498e76f62 ON public.merge_requests USING btree (target_project_id, merged_commit_sha);


--
-- Name: idx_on_target_project_id_squash_commit_sha_ae9a9a8632; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_target_project_id_squash_commit_sha_ae9a9a8632 ON public.merge_requests USING btree (target_project_id, squash_commit_sha);


--
-- Name: idx_pat_last_used_ips_on_pat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pat_last_used_ips_on_pat_id ON public.personal_access_token_last_used_ips USING btree (personal_access_token_id);


--
-- Name: idx_pat_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_pat_on_token_digest ON public.personal_access_tokens USING btree (token_digest);


--
-- Name: idx_pat_on_user_id_and_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pat_on_user_id_and_expires_at ON public.personal_access_tokens USING btree (user_id, expires_at);


--
-- Name: idx_pat_on_user_id_and_last_used_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pat_on_user_id_and_last_used_at ON public.personal_access_tokens USING btree (user_id, last_used_at, id);


--
-- Name: index_board_stages_on_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_stages_on_board_id ON public.board_stages USING btree (board_id);


--
-- Name: index_board_stages_on_board_id_and_closed_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_board_stages_on_board_id_and_closed_kind ON public.board_stages USING btree (board_id, kind) WHERE (kind = 2);


--
-- Name: index_boards_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_namespace_id ON public.boards USING btree (namespace_id);


--
-- Name: index_boards_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_updated_by_id ON public.boards USING btree (updated_by_id);


--
-- Name: index_ci_build_needs_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_needs_on_build_id ON public.ci_build_needs USING btree (build_id);


--
-- Name: index_ci_build_needs_on_build_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_build_needs_on_build_id_and_name ON public.ci_build_needs USING btree (build_id, name);


--
-- Name: index_ci_build_needs_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_needs_on_project_id ON public.ci_build_needs USING btree (project_id);


--
-- Name: index_ci_build_pending_states_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_build_pending_states_on_build_id ON public.ci_build_pending_states USING btree (build_id);


--
-- Name: index_ci_build_pending_states_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_pending_states_on_project_id ON public.ci_build_pending_states USING btree (project_id);


--
-- Name: index_ci_build_sources_on_pipeline_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_sources_on_pipeline_source ON public.ci_build_sources USING btree (pipeline_source);


--
-- Name: index_ci_build_sources_on_project_id_and_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_sources_on_project_id_and_build_id ON public.ci_build_sources USING btree (project_id, build_id);


--
-- Name: index_ci_build_sources_on_project_id_and_source_and_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_sources_on_project_id_and_source_and_build_id ON public.ci_build_sources USING btree (project_id, source, build_id);


--
-- Name: index_ci_build_tags_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_tags_on_build_id ON public.ci_build_tags USING btree (build_id);


--
-- Name: index_ci_build_tags_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_tags_on_project_id ON public.ci_build_tags USING btree (project_id);


--
-- Name: index_ci_build_tags_on_tag_id_and_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_build_tags_on_tag_id_and_build_id ON public.ci_build_tags USING btree (tag_id, build_id);


--
-- Name: index_ci_build_trace_chunks_on_build_id_and_chunk_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_build_trace_chunks_on_build_id_and_chunk_index ON public.ci_build_trace_chunks USING btree (build_id, chunk_index);


--
-- Name: index_ci_build_trace_chunks_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_trace_chunks_on_project_id ON public.ci_build_trace_chunks USING btree (project_id);


--
-- Name: index_ci_build_trace_metadata_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_build_trace_metadata_on_build_id ON public.ci_build_trace_metadata USING btree (build_id);


--
-- Name: index_ci_build_trace_metadata_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_trace_metadata_on_project_id ON public.ci_build_trace_metadata USING btree (project_id);


--
-- Name: index_ci_build_trace_metadata_on_trace_artifact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_build_trace_metadata_on_trace_artifact_id ON public.ci_build_trace_metadata USING btree (trace_artifact_id);


--
-- Name: index_ci_builds_execution_configs_on_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_execution_configs_on_pipeline_id ON public.ci_builds_execution_configs USING btree (pipeline_id);


--
-- Name: index_ci_builds_execution_configs_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_execution_configs_on_project_id ON public.ci_builds_execution_configs USING btree (project_id);


--
-- Name: index_ci_builds_metadata_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_builds_metadata_on_build_id ON public.ci_builds_metadata USING btree (build_id);


--
-- Name: index_ci_builds_metadata_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_metadata_on_project_id ON public.ci_builds_metadata USING btree (project_id);


--
-- Name: index_ci_builds_on_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_commit_id ON public.ci_builds USING btree (commit_id);


--
-- Name: index_ci_builds_on_commit_id_and_status_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_commit_id_and_status_and_type ON public.ci_builds USING btree (commit_id, status, type);


--
-- Name: index_ci_builds_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_project_id ON public.ci_builds USING btree (project_id);


--
-- Name: index_ci_builds_on_project_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_project_id_and_status ON public.ci_builds USING btree (project_id, status);


--
-- Name: index_ci_builds_on_runner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_runner_id ON public.ci_builds USING btree (runner_id);


--
-- Name: index_ci_builds_on_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_stage_id ON public.ci_builds USING btree (stage_id);


--
-- Name: index_ci_builds_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_status ON public.ci_builds USING btree (status);


--
-- Name: index_ci_builds_on_token_encrypted; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_builds_on_token_encrypted ON public.ci_builds USING btree (token_encrypted) WHERE (token_encrypted IS NOT NULL);


--
-- Name: index_ci_builds_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_on_user_id ON public.ci_builds USING btree (user_id);


--
-- Name: index_ci_builds_runner_session_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_builds_runner_session_on_build_id ON public.ci_builds_runner_session USING btree (build_id);


--
-- Name: index_ci_builds_runner_session_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_builds_runner_session_on_project_id ON public.ci_builds_runner_session USING btree (project_id);


--
-- Name: index_ci_instance_variables_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_instance_variables_on_key ON public.ci_instance_variables USING btree (key);


--
-- Name: index_ci_job_artifacts_on_expire_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_job_artifacts_on_expire_at ON public.ci_job_artifacts USING btree (expire_at);


--
-- Name: index_ci_job_artifacts_on_file_store; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_job_artifacts_on_file_store ON public.ci_job_artifacts USING btree (file_store);


--
-- Name: index_ci_job_artifacts_on_job_id_and_file_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_job_artifacts_on_job_id_and_file_type ON public.ci_job_artifacts USING btree (job_id, file_type);


--
-- Name: index_ci_job_artifacts_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_job_artifacts_on_project_id ON public.ci_job_artifacts USING btree (project_id);


--
-- Name: index_ci_job_variables_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_job_variables_on_job_id ON public.ci_job_variables USING btree (job_id);


--
-- Name: index_ci_job_variables_on_key_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_job_variables_on_key_and_job_id ON public.ci_job_variables USING btree (key, job_id);


--
-- Name: index_ci_job_variables_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_job_variables_on_project_id ON public.ci_job_variables USING btree (project_id);


--
-- Name: index_ci_pending_builds_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_pending_builds_on_build_id ON public.ci_pending_builds USING btree (build_id);


--
-- Name: index_ci_pending_builds_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pending_builds_on_namespace_id ON public.ci_pending_builds USING btree (namespace_id);


--
-- Name: index_ci_pending_builds_on_namespace_traversal_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pending_builds_on_namespace_traversal_ids ON public.ci_pending_builds USING gin (namespace_traversal_ids);


--
-- Name: index_ci_pending_builds_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pending_builds_on_plan_id ON public.ci_pending_builds USING btree (plan_id);


--
-- Name: index_ci_pending_builds_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pending_builds_on_project_id ON public.ci_pending_builds USING btree (project_id);


--
-- Name: index_ci_pipeline_messages_on_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipeline_messages_on_pipeline_id ON public.ci_pipeline_messages USING btree (pipeline_id);


--
-- Name: index_ci_pipeline_messages_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipeline_messages_on_project_id ON public.ci_pipeline_messages USING btree (project_id);


--
-- Name: index_ci_pipeline_metadata_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipeline_metadata_on_project_id ON public.ci_pipeline_metadata USING btree (project_id);


--
-- Name: index_ci_pipeline_variables_on_pipeline_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_pipeline_variables_on_pipeline_id_and_key ON public.ci_pipeline_variables USING btree (pipeline_id, key);


--
-- Name: index_ci_pipeline_variables_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipeline_variables_on_project_id ON public.ci_pipeline_variables USING btree (project_id);


--
-- Name: index_ci_pipelines_on_auto_canceled_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_auto_canceled_by_id ON public.ci_pipelines USING btree (auto_canceled_by_id);


--
-- Name: index_ci_pipelines_on_ci_ref_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_ci_ref_id ON public.ci_pipelines USING btree (ci_ref_id);


--
-- Name: index_ci_pipelines_on_merge_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_merge_request_id ON public.ci_pipelines USING btree (merge_request_id);


--
-- Name: index_ci_pipelines_on_pipeline_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_pipeline_schedule_id ON public.ci_pipelines USING btree (pipeline_schedule_id);


--
-- Name: index_ci_pipelines_on_project_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_project_id_and_id ON public.ci_pipelines USING btree (project_id, id);


--
-- Name: index_ci_pipelines_on_project_id_and_iid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_pipelines_on_project_id_and_iid ON public.ci_pipelines USING btree (project_id, iid) WHERE (iid IS NOT NULL);


--
-- Name: index_ci_pipelines_on_project_id_and_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_project_id_and_ref ON public.ci_pipelines USING btree (project_id, ref);


--
-- Name: index_ci_pipelines_on_project_id_and_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_project_id_and_sha ON public.ci_pipelines USING btree (project_id, sha);


--
-- Name: index_ci_pipelines_on_project_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_project_id_and_status ON public.ci_pipelines USING btree (project_id, status);


--
-- Name: index_ci_pipelines_on_status_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_status_and_id ON public.ci_pipelines USING btree (status, id);


--
-- Name: index_ci_pipelines_on_trigger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_trigger_id ON public.ci_pipelines USING btree (trigger_id);


--
-- Name: index_ci_pipelines_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_pipelines_on_user_id ON public.ci_pipelines USING btree (user_id);


--
-- Name: index_ci_refs_on_project_id_and_ref_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_refs_on_project_id_and_ref_path ON public.ci_refs USING btree (project_id, ref_path);


--
-- Name: index_ci_runner_machine_builds_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machine_builds_on_project_id ON public.ci_runner_machine_builds USING btree (project_id);


--
-- Name: index_ci_runner_machine_builds_on_runner_machine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machine_builds_on_runner_machine_id ON public.ci_runner_machine_builds USING btree (runner_machine_id);


--
-- Name: index_ci_runner_machines_on_contacted_at_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_contacted_at_and_id ON public.ci_runner_machines USING btree (contacted_at, id);


--
-- Name: index_ci_runner_machines_on_created_at_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_created_at_and_id ON public.ci_runner_machines USING btree (created_at, id);


--
-- Name: index_ci_runner_machines_on_executor_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_executor_type ON public.ci_runner_machines USING btree (executor_type);


--
-- Name: index_ci_runner_machines_on_ip_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_ip_address ON public.ci_runner_machines USING btree (ip_address);


--
-- Name: index_ci_runner_machines_on_sharding_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_sharding_key_id ON public.ci_runner_machines USING btree (sharding_key_id);


--
-- Name: index_ci_runner_machines_on_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_machines_on_version ON public.ci_runner_machines USING btree (version);


--
-- Name: index_ci_runner_taggings_on_runner_id_and_runner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_taggings_on_runner_id_and_runner_type ON public.ci_runner_taggings USING btree (runner_id, runner_type);


--
-- Name: index_ci_runner_taggings_on_sharding_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runner_taggings_on_sharding_key_id ON public.ci_runner_taggings USING btree (sharding_key_id);


--
-- Name: index_ci_runner_versions_on_status_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_runner_versions_on_status_and_version ON public.ci_runner_versions USING btree (status, version);


--
-- Name: index_ci_runners_on_active_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_active_and_id ON public.ci_runners USING btree (active, id);


--
-- Name: index_ci_runners_on_contacted_at_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_contacted_at_and_id ON public.ci_runners USING btree (contacted_at, id);


--
-- Name: index_ci_runners_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_creator_id ON public.ci_runners USING btree (creator_id);


--
-- Name: index_ci_runners_on_locked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_locked ON public.ci_runners USING btree (locked);


--
-- Name: index_ci_runners_on_runner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_runner_type ON public.ci_runners USING btree (runner_type);


--
-- Name: index_ci_runners_on_sharding_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_sharding_key_id ON public.ci_runners USING btree (sharding_key_id);


--
-- Name: index_ci_runners_on_token_and_runner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_runners_on_token_and_runner_type ON public.ci_runners USING btree (token, runner_type) WHERE (token IS NOT NULL);


--
-- Name: index_ci_runners_on_token_expires_at_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_runners_on_token_expires_at_and_id ON public.ci_runners USING btree (token_expires_at, id);


--
-- Name: index_ci_running_builds_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_running_builds_on_build_id ON public.ci_running_builds USING btree (build_id);


--
-- Name: index_ci_running_builds_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_running_builds_on_project_id ON public.ci_running_builds USING btree (project_id);


--
-- Name: index_ci_running_builds_on_runner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_running_builds_on_runner_id ON public.ci_running_builds USING btree (runner_id);


--
-- Name: index_ci_sources_pipelines_on_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_sources_pipelines_on_pipeline_id ON public.ci_sources_pipelines USING btree (pipeline_id);


--
-- Name: index_ci_sources_pipelines_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_sources_pipelines_on_project_id ON public.ci_sources_pipelines USING btree (project_id);


--
-- Name: index_ci_sources_pipelines_on_source_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_sources_pipelines_on_source_job_id ON public.ci_sources_pipelines USING btree (source_job_id);


--
-- Name: index_ci_sources_pipelines_on_source_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_sources_pipelines_on_source_pipeline_id ON public.ci_sources_pipelines USING btree (source_pipeline_id);


--
-- Name: index_ci_sources_pipelines_on_source_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_sources_pipelines_on_source_project_id ON public.ci_sources_pipelines USING btree (source_project_id);


--
-- Name: index_ci_stages_on_pipeline_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_stages_on_pipeline_id_and_name ON public.ci_stages USING btree (pipeline_id, name);


--
-- Name: index_ci_stages_on_pipeline_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_stages_on_pipeline_id_and_position ON public.ci_stages USING btree (pipeline_id, "position");


--
-- Name: index_ci_stages_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_stages_on_project_id ON public.ci_stages USING btree (project_id);


--
-- Name: index_ci_triggers_on_encrypted_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_triggers_on_encrypted_token ON public.ci_triggers USING btree (encrypted_token);


--
-- Name: index_ci_triggers_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_triggers_on_owner_id ON public.ci_triggers USING btree (owner_id);


--
-- Name: index_ci_triggers_on_project_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_triggers_on_project_id_and_id ON public.ci_triggers USING btree (project_id, id);


--
-- Name: index_ci_triggers_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_triggers_on_token ON public.ci_triggers USING btree (token);


--
-- Name: index_ci_variables_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ci_variables_on_key ON public.ci_variables USING btree (key);


--
-- Name: index_groups_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_namespace_id ON public.groups USING btree (namespace_id);


--
-- Name: index_internal_ids_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_internal_ids_on_namespace_id ON public.internal_ids USING btree (namespace_id);


--
-- Name: index_internal_ids_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_internal_ids_on_project_id ON public.internal_ids USING btree (project_id);


--
-- Name: index_internal_ids_on_usage_and_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_internal_ids_on_usage_and_namespace_id ON public.internal_ids USING btree (usage, namespace_id) WHERE (namespace_id IS NOT NULL);


--
-- Name: index_internal_ids_on_usage_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_internal_ids_on_usage_and_project_id ON public.internal_ids USING btree (usage, project_id) WHERE (project_id IS NOT NULL);


--
-- Name: index_item_links_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_links_on_namespace_id ON public.item_links USING btree (namespace_id);


--
-- Name: index_item_links_on_source_and_target; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_item_links_on_source_and_target ON public.item_links USING btree (source_id, source_type, target_id, target_type);


--
-- Name: index_item_links_on_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_links_on_source_type ON public.item_links USING btree (source_type);


--
-- Name: index_item_links_on_target_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_links_on_target_type ON public.item_links USING btree (target_type);


--
-- Name: index_keys_on_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_fingerprint ON public.keys USING btree (fingerprint);


--
-- Name: index_keys_on_fingerprint_sha256; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_keys_on_fingerprint_sha256 ON public.keys USING btree (fingerprint_sha256);


--
-- Name: index_keys_on_last_used_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_last_used_at ON public.keys USING btree (last_used_at);


--
-- Name: index_keys_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_user_id ON public.keys USING btree (user_id);


--
-- Name: index_label_links_on_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_label_links_on_label_id ON public.label_links USING btree (label_id);


--
-- Name: index_label_links_on_labelable_id_and_labelable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_label_links_on_labelable_id_and_labelable_type ON public.label_links USING btree (labelable_id, labelable_type);


--
-- Name: index_labels_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_namespace_id ON public.labels USING btree (namespace_id);


--
-- Name: index_labels_on_rank; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_rank ON public.labels USING btree (rank);


--
-- Name: index_members_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_created_by_id ON public.members USING btree (created_by_id);


--
-- Name: index_members_on_namespace_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_namespace_id_and_user_id ON public.members USING btree (namespace_id, user_id);


--
-- Name: index_members_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_type ON public.members USING btree (type);


--
-- Name: index_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_user_id ON public.members USING btree (user_id);


--
-- Name: index_merge_request_assignees_on_merge_request_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_request_assignees_on_merge_request_id_and_user_id ON public.merge_request_assignees USING btree (merge_request_id, user_id);


--
-- Name: index_merge_request_assignees_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_assignees_on_project_id ON public.merge_request_assignees USING btree (project_id);


--
-- Name: index_merge_request_assignees_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_assignees_on_user_id ON public.merge_request_assignees USING btree (user_id);


--
-- Name: index_merge_request_diff_commit_users_on_name_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_request_diff_commit_users_on_name_and_email ON public.merge_request_diff_commit_users USING btree (name, email);


--
-- Name: index_merge_request_diff_commit_users_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diff_commit_users_on_organization_id ON public.merge_request_diff_commit_users USING btree (organization_id);


--
-- Name: index_merge_request_diff_commits_on_commit_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diff_commits_on_commit_author_id ON public.merge_request_diff_commits USING btree (commit_author_id);


--
-- Name: index_merge_request_diff_commits_on_committer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diff_commits_on_committer_id ON public.merge_request_diff_commits USING btree (committer_id);


--
-- Name: index_merge_request_diff_commits_on_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diff_commits_on_sha ON public.merge_request_diff_commits USING btree (sha);


--
-- Name: index_merge_request_diff_files_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diff_files_on_project_id ON public.merge_request_diff_files USING btree (project_id);


--
-- Name: index_merge_request_diffs_on_external_diff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diffs_on_external_diff ON public.merge_request_diffs USING btree (external_diff);


--
-- Name: index_merge_request_diffs_on_external_diff_store; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diffs_on_external_diff_store ON public.merge_request_diffs USING btree (external_diff_store);


--
-- Name: index_merge_request_diffs_on_head_commit_sha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diffs_on_head_commit_sha ON public.merge_request_diffs USING btree (head_commit_sha);


--
-- Name: index_merge_request_diffs_on_merge_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diffs_on_merge_request_id ON public.merge_request_diffs USING btree (merge_request_id);


--
-- Name: index_merge_request_diffs_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_diffs_on_project_id ON public.merge_request_diffs USING btree (project_id);


--
-- Name: index_merge_request_diffs_on_unique_merge_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_request_diffs_on_unique_merge_request_id ON public.merge_request_diffs USING btree (merge_request_id) WHERE (diff_type = 2);


--
-- Name: index_merge_request_metrics_on_latest_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_metrics_on_latest_closed_at ON public.merge_request_metrics USING btree (latest_closed_at);


--
-- Name: index_merge_request_metrics_on_merge_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_request_metrics_on_merge_request_id ON public.merge_request_metrics USING btree (merge_request_id);


--
-- Name: index_merge_request_metrics_on_merged_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_metrics_on_merged_at ON public.merge_request_metrics USING btree (merged_at);


--
-- Name: index_merge_request_metrics_on_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_metrics_on_pipeline_id ON public.merge_request_metrics USING btree (pipeline_id);


--
-- Name: index_merge_request_reviewers_on_merge_request_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_request_reviewers_on_merge_request_id_and_user_id ON public.merge_request_reviewers USING btree (merge_request_id, user_id);


--
-- Name: index_merge_request_reviewers_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_reviewers_on_project_id ON public.merge_request_reviewers USING btree (project_id);


--
-- Name: index_merge_request_reviewers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_reviewers_on_user_id ON public.merge_request_reviewers USING btree (user_id);


--
-- Name: index_merge_request_reviewers_on_user_id_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_request_reviewers_on_user_id_and_state ON public.merge_request_reviewers USING btree (user_id, state) WHERE (state = 2);


--
-- Name: index_merge_requests_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_author_id ON public.merge_requests USING btree (author_id);


--
-- Name: index_merge_requests_on_author_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_author_id_and_created_at ON public.merge_requests USING btree (author_id, created_at);


--
-- Name: index_merge_requests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_created_at ON public.merge_requests USING btree (created_at);


--
-- Name: index_merge_requests_on_head_pipeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_head_pipeline_id ON public.merge_requests USING btree (head_pipeline_id);


--
-- Name: index_merge_requests_on_latest_merge_request_diff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_latest_merge_request_diff_id ON public.merge_requests USING btree (latest_merge_request_diff_id);


--
-- Name: index_merge_requests_on_merge_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_merge_user_id ON public.merge_requests USING btree (merge_user_id);


--
-- Name: index_merge_requests_on_source_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_source_branch ON public.merge_requests USING btree (source_branch);


--
-- Name: index_merge_requests_on_source_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_source_project_id ON public.merge_requests USING btree (source_project_id);


--
-- Name: index_merge_requests_on_source_project_id_and_source_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_source_project_id_and_source_branch ON public.merge_requests USING btree (source_project_id, source_branch);


--
-- Name: index_merge_requests_on_target_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_target_branch ON public.merge_requests USING btree (target_branch);


--
-- Name: index_merge_requests_on_target_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_target_project_id ON public.merge_requests USING btree (target_project_id);


--
-- Name: index_merge_requests_on_target_project_id_and_iid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_merge_requests_on_target_project_id_and_iid ON public.merge_requests USING btree (target_project_id, iid);


--
-- Name: index_merge_requests_on_target_project_id_and_source_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_merge_requests_on_target_project_id_and_source_branch ON public.merge_requests USING btree (target_project_id, source_branch);


--
-- Name: index_namespace_descendants_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespace_descendants_on_namespace_id ON public.namespace_descendants USING btree (namespace_id) WHERE (outdated_at IS NOT NULL);


--
-- Name: index_namespace_settings_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespace_settings_on_namespace_id ON public.namespace_settings USING btree (namespace_id);


--
-- Name: index_namespaces_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_created_at ON public.namespaces USING btree (created_at);


--
-- Name: index_namespaces_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_lower_name ON public.namespaces USING btree (lower((name)::text));


--
-- Name: index_namespaces_on_lower_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_lower_path ON public.namespaces USING btree (lower((path)::text));


--
-- Name: index_namespaces_on_name_and_parent_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespaces_on_name_and_parent_id_and_type ON public.namespaces USING btree (name, parent_id, type);


--
-- Name: index_namespaces_on_parent_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespaces_on_parent_id_and_id ON public.namespaces USING btree (parent_id, id);


--
-- Name: index_namespaces_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_path ON public.namespaces USING btree (path);


--
-- Name: index_namespaces_on_path_and_parent_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_namespaces_on_path_and_parent_id_and_type ON public.namespaces USING btree (path, parent_id, type);


--
-- Name: index_namespaces_on_traversal_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_traversal_ids ON public.namespaces USING gin (traversal_ids);


--
-- Name: index_namespaces_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_namespaces_on_type ON public.namespaces USING btree (type);


--
-- Name: index_note_diff_files_on_diff_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_note_diff_files_on_diff_note_id ON public.note_diff_files USING btree (diff_note_id);


--
-- Name: index_notification_settings_on_source_id_and_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_settings_on_source_id_and_source_type ON public.notification_settings USING btree (source_id, source_type);


--
-- Name: index_notification_settings_on_user_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_settings_on_user_and_source ON public.notification_settings USING btree (user_id, source_type, source_id);


--
-- Name: index_notification_settings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_settings_on_user_id ON public.notification_settings USING btree (user_id);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_created_at_and_expires_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_created_at_and_expires_in ON public.oauth_access_grants USING btree (created_at, expires_in);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_applications_on_owner_id_and_owner_type ON public.oauth_applications USING btree (owner_id, owner_type);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_personal_access_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_personal_access_tokens_on_user_id ON public.personal_access_tokens USING btree (user_id);


--
-- Name: index_plan_limits_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plan_limits_on_plan_id ON public.plan_limits USING btree (plan_id);


--
-- Name: index_project_ci_cd_settings_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_ci_cd_settings_on_project_id ON public.project_ci_cd_settings USING btree (project_id);


--
-- Name: index_project_ci_cd_settings_on_project_id_partial; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_ci_cd_settings_on_project_id_partial ON public.project_ci_cd_settings USING btree (project_id) WHERE (delete_pipelines_in_seconds IS NOT NULL);


--
-- Name: index_project_features_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_features_on_project_id ON public.project_features USING btree (project_id);


--
-- Name: index_project_features_on_project_id_bal_20; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_features_on_project_id_bal_20 ON public.project_features USING btree (project_id) WHERE (builds_access_level = 20);


--
-- Name: index_project_features_on_project_id_on_public_package_registry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_features_on_project_id_on_public_package_registry ON public.project_features USING btree (project_id) WHERE (package_registry_access_level = 30);


--
-- Name: index_project_features_on_project_id_ral_20; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_features_on_project_id_ral_20 ON public.project_features USING btree (project_id) WHERE (repository_access_level = 20);


--
-- Name: index_project_pipeline_settings_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pipeline_settings_on_project_id ON public.project_pipeline_settings USING btree (project_id);


--
-- Name: index_projects_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_lower_name ON public.projects USING btree (lower((name)::text));


--
-- Name: index_projects_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_namespace_id ON public.projects USING btree (namespace_id);


--
-- Name: index_protected_refs_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_refs_on_namespace_id ON public.protected_refs USING btree (namespace_id);


--
-- Name: index_protected_refs_on_namespace_id_and_name_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_protected_refs_on_namespace_id_and_name_and_type ON public.protected_refs USING btree (namespace_id, name, type);


--
-- Name: index_protected_refs_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protected_refs_on_type ON public.protected_refs USING btree (type);


--
-- Name: index_reviews_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_author_id ON public.reviews USING btree (author_id);


--
-- Name: index_reviews_on_merge_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_merge_request_id ON public.reviews USING btree (merge_request_id);


--
-- Name: index_reviews_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reviews_on_project_id ON public.reviews USING btree (project_id);


--
-- Name: index_routes_on_lower_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routes_on_lower_path ON public.routes USING btree (lower((path)::text));


--
-- Name: index_routes_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_routes_on_name ON public.routes USING gin (name public.gin_trgm_ops);


--
-- Name: index_routes_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_routes_on_namespace_id ON public.routes USING btree (namespace_id);


--
-- Name: index_routes_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_routes_on_path ON public.routes USING btree (path);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_uploads_on_checksum; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_checksum ON public.uploads USING btree (checksum);


--
-- Name: index_uploads_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_namespace_id ON public.uploads USING btree (namespace_id);


--
-- Name: index_uploads_on_store; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_store ON public.uploads USING btree (store);


--
-- Name: index_uploads_on_uploaded_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_uploaded_by_user_id ON public.uploads USING btree (uploaded_by_user_id);


--
-- Name: index_uploads_on_uploader_and_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_uploader_and_path ON public.uploads USING btree (uploader, path);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_lower_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_lower_email ON public.users USING btree (lower((email)::text));


--
-- Name: index_users_on_lower_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_lower_username ON public.users USING btree (lower((username)::text));


--
-- Name: index_users_on_mobile; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_mobile ON public.users USING btree (mobile);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_state ON public.users USING btree (state);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_users_on_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_user_type ON public.users USING btree (user_type);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_web_hooks_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_hooks_on_namespace_id ON public.web_hooks USING btree (namespace_id);


--
-- Name: index_web_hooks_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_hooks_on_type ON public.web_hooks USING btree (type);


--
-- Name: index_work_item_assignees_on_assignee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_item_assignees_on_assignee_id ON public.work_item_assignees USING btree (assignee_id);


--
-- Name: index_work_item_assignees_on_work_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_item_assignees_on_work_item_id ON public.work_item_assignees USING btree (work_item_id);


--
-- Name: index_work_item_assignees_on_work_item_id_and_assignee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_work_item_assignees_on_work_item_id_and_assignee_id ON public.work_item_assignees USING btree (work_item_id, assignee_id);


--
-- Name: index_work_items_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_author_id ON public.work_items USING btree (author_id);


--
-- Name: index_work_items_on_closed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_closed_at ON public.work_items USING btree (closed_at);


--
-- Name: index_work_items_on_closed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_closed_by_id ON public.work_items USING btree (closed_by_id);


--
-- Name: index_work_items_on_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_namespace_id ON public.work_items USING btree (namespace_id);


--
-- Name: index_work_items_on_namespace_id_and_type_and_iid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_work_items_on_namespace_id_and_type_and_iid ON public.work_items USING btree (namespace_id, type, iid);


--
-- Name: index_work_items_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_parent_id ON public.work_items USING btree (parent_id);


--
-- Name: index_work_items_on_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_state_id ON public.work_items USING btree (state_id);


--
-- Name: index_work_items_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_type ON public.work_items USING btree (type);


--
-- Name: index_work_items_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_items_on_updated_by_id ON public.work_items USING btree (updated_by_id);


--
-- Name: issue_activities_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_activities_author_id_idx ON public.issue_activities USING btree (author_id);


--
-- Name: issue_activities_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_activities_created_at_idx ON public.issue_activities USING btree (created_at);


--
-- Name: issue_activities_note_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_activities_note_id_idx ON public.issue_activities USING btree (note_id);


--
-- Name: issue_activities_trackable_type_trackable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_activities_trackable_type_trackable_id_idx ON public.issue_activities USING btree (trackable_type, trackable_id);


--
-- Name: issue_notes_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_author_id_idx ON public.issue_notes USING btree (author_id);


--
-- Name: issue_notes_confidential_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_confidential_idx ON public.issue_notes USING btree (confidential);


--
-- Name: issue_notes_discussion_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_discussion_id_idx ON public.issue_notes USING btree (discussion_id);


--
-- Name: issue_notes_internal_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_internal_idx ON public.issue_notes USING btree (internal);


--
-- Name: issue_notes_namespace_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_namespace_id_idx ON public.issue_notes USING btree (namespace_id);


--
-- Name: issue_notes_noteable_type_noteable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_noteable_type_noteable_id_idx ON public.issue_notes USING btree (noteable_type, noteable_id);


--
-- Name: issue_notes_resolved_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_resolved_at_idx ON public.issue_notes USING btree (resolved_at);


--
-- Name: issue_notes_resolved_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_resolved_by_id_idx ON public.issue_notes USING btree (resolved_by_id);


--
-- Name: issue_notes_system_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_system_idx ON public.issue_notes USING btree (system);


--
-- Name: issue_notes_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_type_idx ON public.issue_notes USING btree (type);


--
-- Name: issue_notes_updated_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_notes_updated_by_id_idx ON public.issue_notes USING btree (updated_by_id);


--
-- Name: merge_request_activities_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_activities_author_id_idx ON public.merge_request_activities USING btree (author_id);


--
-- Name: merge_request_activities_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_activities_created_at_idx ON public.merge_request_activities USING btree (created_at);


--
-- Name: merge_request_activities_note_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_activities_note_id_idx ON public.merge_request_activities USING btree (note_id);


--
-- Name: merge_request_activities_trackable_type_trackable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_activities_trackable_type_trackable_id_idx ON public.merge_request_activities USING btree (trackable_type, trackable_id);


--
-- Name: merge_request_notes_author_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_author_id_idx ON public.merge_request_notes USING btree (author_id);


--
-- Name: merge_request_notes_confidential_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_confidential_idx ON public.merge_request_notes USING btree (confidential);


--
-- Name: merge_request_notes_discussion_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_discussion_id_idx ON public.merge_request_notes USING btree (discussion_id);


--
-- Name: merge_request_notes_internal_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_internal_idx ON public.merge_request_notes USING btree (internal);


--
-- Name: merge_request_notes_namespace_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_namespace_id_idx ON public.merge_request_notes USING btree (namespace_id);


--
-- Name: merge_request_notes_noteable_type_noteable_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_noteable_type_noteable_id_idx ON public.merge_request_notes USING btree (noteable_type, noteable_id);


--
-- Name: merge_request_notes_resolved_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_resolved_at_idx ON public.merge_request_notes USING btree (resolved_at);


--
-- Name: merge_request_notes_resolved_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_resolved_by_id_idx ON public.merge_request_notes USING btree (resolved_by_id);


--
-- Name: merge_request_notes_system_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_system_idx ON public.merge_request_notes USING btree (system);


--
-- Name: merge_request_notes_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_type_idx ON public.merge_request_notes USING btree (type);


--
-- Name: merge_request_notes_updated_by_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX merge_request_notes_updated_by_id_idx ON public.merge_request_notes USING btree (updated_by_id);


--
-- Name: epic_activities_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_author_id ATTACH PARTITION public.epic_activities_author_id_idx;


--
-- Name: epic_activities_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_created_at ATTACH PARTITION public.epic_activities_created_at_idx;


--
-- Name: epic_activities_note_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_note_id ATTACH PARTITION public.epic_activities_note_id_idx;


--
-- Name: epic_activities_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activities_pkey ATTACH PARTITION public.epic_activities_pkey;


--
-- Name: epic_activities_trackable_type_trackable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_trackable_type_and_trackable_id ATTACH PARTITION public.epic_activities_trackable_type_trackable_id_idx;


--
-- Name: epic_notes_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_author_id ATTACH PARTITION public.epic_notes_author_id_idx;


--
-- Name: epic_notes_confidential_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_confidential ATTACH PARTITION public.epic_notes_confidential_idx;


--
-- Name: epic_notes_discussion_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_discussion_id ATTACH PARTITION public.epic_notes_discussion_id_idx;


--
-- Name: epic_notes_internal_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_internal ATTACH PARTITION public.epic_notes_internal_idx;


--
-- Name: epic_notes_namespace_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_namespace_id ATTACH PARTITION public.epic_notes_namespace_id_idx;


--
-- Name: epic_notes_noteable_type_noteable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_noteable_type_and_noteable_id ATTACH PARTITION public.epic_notes_noteable_type_noteable_id_idx;


--
-- Name: epic_notes_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.notes_pkey ATTACH PARTITION public.epic_notes_pkey;


--
-- Name: epic_notes_resolved_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_at ATTACH PARTITION public.epic_notes_resolved_at_idx;


--
-- Name: epic_notes_resolved_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_by_id ATTACH PARTITION public.epic_notes_resolved_by_id_idx;


--
-- Name: epic_notes_system_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_system ATTACH PARTITION public.epic_notes_system_idx;


--
-- Name: epic_notes_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_type ATTACH PARTITION public.epic_notes_type_idx;


--
-- Name: epic_notes_updated_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_updated_by_id ATTACH PARTITION public.epic_notes_updated_by_id_idx;


--
-- Name: issue_activities_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_author_id ATTACH PARTITION public.issue_activities_author_id_idx;


--
-- Name: issue_activities_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_created_at ATTACH PARTITION public.issue_activities_created_at_idx;


--
-- Name: issue_activities_note_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_note_id ATTACH PARTITION public.issue_activities_note_id_idx;


--
-- Name: issue_activities_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activities_pkey ATTACH PARTITION public.issue_activities_pkey;


--
-- Name: issue_activities_trackable_type_trackable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_trackable_type_and_trackable_id ATTACH PARTITION public.issue_activities_trackable_type_trackable_id_idx;


--
-- Name: issue_notes_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_author_id ATTACH PARTITION public.issue_notes_author_id_idx;


--
-- Name: issue_notes_confidential_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_confidential ATTACH PARTITION public.issue_notes_confidential_idx;


--
-- Name: issue_notes_discussion_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_discussion_id ATTACH PARTITION public.issue_notes_discussion_id_idx;


--
-- Name: issue_notes_internal_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_internal ATTACH PARTITION public.issue_notes_internal_idx;


--
-- Name: issue_notes_namespace_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_namespace_id ATTACH PARTITION public.issue_notes_namespace_id_idx;


--
-- Name: issue_notes_noteable_type_noteable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_noteable_type_and_noteable_id ATTACH PARTITION public.issue_notes_noteable_type_noteable_id_idx;


--
-- Name: issue_notes_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.notes_pkey ATTACH PARTITION public.issue_notes_pkey;


--
-- Name: issue_notes_resolved_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_at ATTACH PARTITION public.issue_notes_resolved_at_idx;


--
-- Name: issue_notes_resolved_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_by_id ATTACH PARTITION public.issue_notes_resolved_by_id_idx;


--
-- Name: issue_notes_system_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_system ATTACH PARTITION public.issue_notes_system_idx;


--
-- Name: issue_notes_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_type ATTACH PARTITION public.issue_notes_type_idx;


--
-- Name: issue_notes_updated_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_updated_by_id ATTACH PARTITION public.issue_notes_updated_by_id_idx;


--
-- Name: merge_request_activities_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_author_id ATTACH PARTITION public.merge_request_activities_author_id_idx;


--
-- Name: merge_request_activities_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_created_at ATTACH PARTITION public.merge_request_activities_created_at_idx;


--
-- Name: merge_request_activities_note_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_note_id ATTACH PARTITION public.merge_request_activities_note_id_idx;


--
-- Name: merge_request_activities_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.activities_pkey ATTACH PARTITION public.merge_request_activities_pkey;


--
-- Name: merge_request_activities_trackable_type_trackable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_activities_on_trackable_type_and_trackable_id ATTACH PARTITION public.merge_request_activities_trackable_type_trackable_id_idx;


--
-- Name: merge_request_notes_author_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_author_id ATTACH PARTITION public.merge_request_notes_author_id_idx;


--
-- Name: merge_request_notes_confidential_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_confidential ATTACH PARTITION public.merge_request_notes_confidential_idx;


--
-- Name: merge_request_notes_discussion_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_discussion_id ATTACH PARTITION public.merge_request_notes_discussion_id_idx;


--
-- Name: merge_request_notes_internal_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_internal ATTACH PARTITION public.merge_request_notes_internal_idx;


--
-- Name: merge_request_notes_namespace_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_namespace_id ATTACH PARTITION public.merge_request_notes_namespace_id_idx;


--
-- Name: merge_request_notes_noteable_type_noteable_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_noteable_type_and_noteable_id ATTACH PARTITION public.merge_request_notes_noteable_type_noteable_id_idx;


--
-- Name: merge_request_notes_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.notes_pkey ATTACH PARTITION public.merge_request_notes_pkey;


--
-- Name: merge_request_notes_resolved_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_at ATTACH PARTITION public.merge_request_notes_resolved_at_idx;


--
-- Name: merge_request_notes_resolved_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_resolved_by_id ATTACH PARTITION public.merge_request_notes_resolved_by_id_idx;


--
-- Name: merge_request_notes_system_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_system ATTACH PARTITION public.merge_request_notes_system_idx;


--
-- Name: merge_request_notes_type_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_type ATTACH PARTITION public.merge_request_notes_type_idx;


--
-- Name: merge_request_notes_updated_by_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_notes_on_updated_by_id ATTACH PARTITION public.merge_request_notes_updated_by_id_idx;


--
-- Name: notes fk_rails_36c9deba43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notes
    ADD CONSTRAINT fk_rails_36c9deba43 FOREIGN KEY (author_id) REFERENCES public.users(id);


--
-- Name: notes fk_rails_6e1963e950; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notes
    ADD CONSTRAINT fk_rails_6e1963e950 FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: ci_pending_builds fk_rails_725a2644a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_pending_builds
    ADD CONSTRAINT fk_rails_725a2644a3 FOREIGN KEY (build_id) REFERENCES public.ci_builds(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_76db6d50c6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notes
    ADD CONSTRAINT fk_rails_76db6d50c6 FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: notes fk_rails_8027c2404e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notes
    ADD CONSTRAINT fk_rails_8027c2404e FOREIGN KEY (resolved_by_id) REFERENCES public.users(id);


--
-- Name: label_links fk_rails_d97dd08678; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_links
    ADD CONSTRAINT fk_rails_d97dd08678 FOREIGN KEY (label_id) REFERENCES public.labels(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260504104200'),
('20260501134632'),
('20260501134333'),
('20260430060808'),
('20260429131634'),
('20260429131429'),
('20260418134212'),
('20260415143742'),
('20260414144523'),
('20260414084840'),
('20260412081139'),
('20260408062525'),
('20260318052307'),
('20260313154116'),
('20260313133856'),
('20260313082820'),
('20260312151247'),
('20260303033611'),
('20260219093655'),
('20260217142228'),
('20260217132430'),
('20260217132421'),
('20260217091012'),
('20260215144032'),
('20260210125013'),
('20260210034916'),
('20260210031106'),
('20260209135517'),
('20260209134658'),
('20260209133940'),
('20260207093159'),
('20251113082640'),
('20251113081628'),
('20251112151807'),
('20251112141231'),
('20251111145328'),
('20251111143812'),
('20251111143030'),
('20251110015950'),
('20251109083811'),
('20251109082817'),
('20251031152851'),
('20251031144811'),
('20251031134526'),
('20251031134508'),
('20251031053851'),
('20251027145625'),
('20251027143233'),
('20251027143127'),
('20251022072049'),
('20251022063810'),
('20251022063805'),
('20251022060046'),
('20251022054719'),
('20251022054526'),
('20251022054356'),
('20251021155755'),
('20251021154337'),
('20251021143327'),
('20251021033018'),
('20251021030929'),
('20251020083414'),
('20251017060921'),
('20251017055554'),
('20251017055351'),
('20251017055131'),
('20251017051944'),
('20251017051906'),
('20251017051727'),
('20251017051126'),
('20251017050912'),
('20251017050828'),
('20251017050501'),
('20251017050352'),
('20251017045616'),
('20251017045302'),
('20251017045213'),
('20251017045035'),
('20251017044902'),
('20251017044756'),
('20251017044608'),
('20251017040452'),
('20251017040411'),
('20251017040325'),
('20251017040105'),
('20251017040010'),
('20251017035911'),
('20251017035735'),
('20251017035600'),
('20251017035512'),
('20251017035408'),
('20251017035329'),
('20251017035223'),
('20251017035113'),
('20251017034756'),
('20251017034714'),
('20251017034633'),
('20251017034559'),
('20251017034527'),
('20251017034322'),
('20251017030621'),
('20251017030538'),
('20251017030447'),
('20251017030336'),
('20251017030238'),
('20251017030144'),
('20251017030038'),
('20251017025338'),
('20251017025244'),
('20251017024857'),
('20251017024124'),
('20251017024032'),
('20251017023948'),
('20251017023849'),
('20251017022709'),
('20251017022057'),
('20251017022002'),
('20251017021905'),
('20251017021621'),
('20251015084716'),
('20251015084543'),
('20251015084301'),
('20251015084115'),
('20251015083905'),
('20251015083707'),
('20251015082508'),
('20251015082218'),
('20251015075620'),
('20251015075518'),
('20251015074847'),
('20251015074702'),
('20251015074045'),
('20251015065604');

