--
-- PostgreSQL database dump
--

\restrict rKvBXybkIfu1SS1mvzPz3o9hhicQaQv2d03yhmwmo3yQ2ylml157IiH2Ecrxcyd

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: caretakers_permissions_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.caretakers_permissions_enum AS ENUM (
    'read_only',
    'full_access',
    'financial_access'
);


ALTER TYPE public.caretakers_permissions_enum OWNER TO root;

--
-- Name: caretakers_status_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.caretakers_status_enum AS ENUM (
    'active',
    'inactive',
    'suspended'
);


ALTER TYPE public.caretakers_status_enum OWNER TO root;

--
-- Name: invoices_paymentmethod_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.invoices_paymentmethod_enum AS ENUM (
    'cash',
    'bank_transfer',
    'bkash',
    'nagad',
    'rocket'
);


ALTER TYPE public.invoices_paymentmethod_enum OWNER TO root;

--
-- Name: invoices_status_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.invoices_status_enum AS ENUM (
    'draft',
    'sent',
    'paid',
    'overdue',
    'cancelled'
);


ALTER TYPE public.invoices_status_enum OWNER TO root;

--
-- Name: properties_status_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.properties_status_enum AS ENUM (
    'available',
    'occupied',
    'maintenance',
    'rented'
);


ALTER TYPE public.properties_status_enum OWNER TO root;

--
-- Name: properties_type_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.properties_type_enum AS ENUM (
    'apartment',
    'house',
    'commercial',
    'land'
);


ALTER TYPE public.properties_type_enum OWNER TO root;

--
-- Name: tenants_status_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.tenants_status_enum AS ENUM (
    'pending',
    'active',
    'inactive',
    'terminated'
);


ALTER TYPE public.tenants_status_enum OWNER TO root;

--
-- Name: users_role_enum; Type: TYPE; Schema: public; Owner: root
--

CREATE TYPE public.users_role_enum AS ENUM (
    'super_admin',
    'admin',
    'user'
);


ALTER TYPE public.users_role_enum OWNER TO root;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: caretakers; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.caretakers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "propertyId" uuid NOT NULL,
    status public.caretakers_status_enum DEFAULT 'active'::public.caretakers_status_enum NOT NULL,
    permissions public.caretakers_permissions_enum DEFAULT 'full_access'::public.caretakers_permissions_enum NOT NULL,
    "startDate" date NOT NULL,
    "endDate" date,
    notes text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.caretakers OWNER TO root;

--
-- Name: invoices; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.invoices (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "invoiceNumber" character varying(100) NOT NULL,
    "propertyId" uuid NOT NULL,
    "tenantId" uuid NOT NULL,
    "invoiceMonth" date NOT NULL,
    status public.invoices_status_enum DEFAULT 'draft'::public.invoices_status_enum NOT NULL,
    "rentAmount" numeric(10,2) NOT NULL,
    "gasAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "waterAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "electricityAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "parkingAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "serviceAmount" numeric(10,2) DEFAULT '0'::numeric NOT NULL,
    "additionalCharges" json,
    "totalAmount" numeric(10,2) NOT NULL,
    "dueDate" date NOT NULL,
    "paymentDate" date,
    "paymentMethod" public.invoices_paymentmethod_enum,
    "transactionReference" character varying(255),
    "paymentNotes" text,
    notes text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.invoices OWNER TO root;

--
-- Name: properties; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.properties (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "uniqueId" character varying(100) NOT NULL,
    description text,
    address text NOT NULL,
    type public.properties_type_enum NOT NULL,
    status public.properties_status_enum DEFAULT 'available'::public.properties_status_enum NOT NULL,
    area numeric(10,2),
    bedrooms integer,
    bathrooms integer,
    images json,
    amenities json,
    "ownerId" uuid NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.properties OWNER TO root;

--
-- Name: tenants; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tenants (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "propertyId" uuid NOT NULL,
    status public.tenants_status_enum DEFAULT 'pending'::public.tenants_status_enum NOT NULL,
    "startDate" date NOT NULL,
    "endDate" date,
    "monthlyRent" numeric(10,2) NOT NULL,
    "securityDeposit" numeric(10,2),
    notes text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tenants OWNER TO root;

--
-- Name: users; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    phone character varying(20) NOT NULL,
    email character varying(255),
    "nationalId" character varying(50),
    password character varying(255) NOT NULL,
    role public.users_role_enum DEFAULT 'user'::public.users_role_enum NOT NULL,
    "isVerified" boolean DEFAULT false NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "lastLoginAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO root;

--
-- Data for Name: caretakers; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.caretakers (id, "userId", "propertyId", status, permissions, "startDate", "endDate", notes, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.invoices (id, "invoiceNumber", "propertyId", "tenantId", "invoiceMonth", status, "rentAmount", "gasAmount", "waterAmount", "electricityAmount", "parkingAmount", "serviceAmount", "additionalCharges", "totalAmount", "dueDate", "paymentDate", "paymentMethod", "transactionReference", "paymentNotes", notes, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.properties (id, name, "uniqueId", description, address, type, status, area, bedrooms, bathrooms, images, amenities, "ownerId", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: tenants; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tenants (id, "userId", "propertyId", status, "startDate", "endDate", "monthlyRent", "securityDeposit", notes, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.users (id, name, phone, email, "nationalId", password, role, "isVerified", "isActive", "lastLoginAt", "createdAt", "updatedAt") FROM stdin;
\.


--
-- Name: properties PK_2d83bfa0b9fcd45dee1785af44d; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT "PK_2d83bfa0b9fcd45dee1785af44d" PRIMARY KEY (id);


--
-- Name: tenants PK_53be67a04681c66b87ee27c9321; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT "PK_53be67a04681c66b87ee27c9321" PRIMARY KEY (id);


--
-- Name: invoices PK_668cef7c22a427fd822cc1be3ce; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "PK_668cef7c22a427fd822cc1be3ce" PRIMARY KEY (id);


--
-- Name: caretakers PK_9cf63440d0ad638d954969a65b7; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.caretakers
    ADD CONSTRAINT "PK_9cf63440d0ad638d954969a65b7" PRIMARY KEY (id);


--
-- Name: users PK_a3ffb1c0c8416b9fc6f907b7433; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);


--
-- Name: properties UQ_20a1a96124844b6e964e290de50; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT "UQ_20a1a96124844b6e964e290de50" UNIQUE ("uniqueId");


--
-- Name: users UQ_a000cca60bcf04454e727699490; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_a000cca60bcf04454e727699490" UNIQUE (phone);


--
-- Name: invoices UQ_bf8e0f9dd4558ef209ec111782d; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "UQ_bf8e0f9dd4558ef209ec111782d" UNIQUE ("invoiceNumber");


--
-- Name: tenants FK_40b6986ec14295696de254b13d9; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT "FK_40b6986ec14295696de254b13d9" FOREIGN KEY ("propertyId") REFERENCES public.properties(id);


--
-- Name: properties FK_47b8bfd9c3165b8a53cd0c58df0; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT "FK_47b8bfd9c3165b8a53cd0c58df0" FOREIGN KEY ("ownerId") REFERENCES public.users(id);


--
-- Name: invoices FK_7d55de85575f6e5b205fd6ae4b0; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "FK_7d55de85575f6e5b205fd6ae4b0" FOREIGN KEY ("propertyId") REFERENCES public.properties(id);


--
-- Name: invoices FK_89c82485e364081f457b210120d; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT "FK_89c82485e364081f457b210120d" FOREIGN KEY ("tenantId") REFERENCES public.tenants(id);


--
-- Name: caretakers FK_c54441bbd035138b2fde94393fa; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.caretakers
    ADD CONSTRAINT "FK_c54441bbd035138b2fde94393fa" FOREIGN KEY ("propertyId") REFERENCES public.properties(id);


--
-- Name: tenants FK_e599183d152a58fb0936b70ac5d; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT "FK_e599183d152a58fb0936b70ac5d" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: caretakers FK_fbfc191c37517dceae11702d0a1; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.caretakers
    ADD CONSTRAINT "FK_fbfc191c37517dceae11702d0a1" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict rKvBXybkIfu1SS1mvzPz3o9hhicQaQv2d03yhmwmo3yQ2ylml157IiH2Ecrxcyd

