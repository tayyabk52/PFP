-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.auction_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL,
  listing_id uuid NOT NULL,
  notification_type USER-DEFINED NOT NULL,
  notification_text text NOT NULL,
  link_url text NOT NULL,
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT auction_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT auction_notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES auth.users(id),
  CONSTRAINT auction_notifications_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id)
);
CREATE TABLE public.badge_audit_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  action text NOT NULL CHECK (action = ANY (ARRAY['granted'::text, 'revoked'::text])),
  performed_by uuid NOT NULL,
  reason text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT badge_audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT badge_audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT badge_audit_log_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES auth.users(id)
);
CREATE TABLE public.bids (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL,
  bidder_id uuid NOT NULL,
  bid_amount integer NOT NULL CHECK (bid_amount > 0),
  placed_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT bids_pkey PRIMARY KEY (id),
  CONSTRAINT bids_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id),
  CONSTRAINT bids_bidder_id_fkey FOREIGN KEY (bidder_id) REFERENCES auth.users(id)
);
CREATE TABLE public.case_activity_log (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL,
  admin_id uuid NOT NULL,
  action text NOT NULL,
  new_status USER-DEFINED,
  public_note text,
  internal_note text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT case_activity_log_pkey PRIMARY KEY (id),
  CONSTRAINT case_activity_log_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT case_activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id)
);
CREATE TABLE public.community_guides (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  body text NOT NULL,
  slug text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'published'::text])),
  author_id uuid NOT NULL,
  published_at timestamp with time zone,
  last_updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT community_guides_pkey PRIMARY KEY (id),
  CONSTRAINT community_guides_author_id_fkey FOREIGN KEY (author_id) REFERENCES auth.users(id)
);
CREATE TABLE public.conversation_listings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  listing_id uuid NOT NULL,
  added_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT conversation_listings_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_listings_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT conversation_listings_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id)
);
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  last_message_at timestamp with time zone,
  buyer_deleted_at timestamp with time zone,
  seller_deleted_at timestamp with time zone,
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES auth.users(id),
  CONSTRAINT conversations_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES auth.users(id)
);
CREATE TABLE public.fake_detection_guides (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fragrance_name text NOT NULL,
  brand text NOT NULL,
  slug text NOT NULL UNIQUE,
  status USER-DEFINED NOT NULL DEFAULT 'pending_review'::guide_status,
  sections jsonb NOT NULL DEFAULT '[]'::jsonb,
  submitted_by uuid,
  approved_by uuid,
  rejection_reason text,
  contributor_credit text NOT NULL DEFAULT 'PFC Admin'::text,
  published_at timestamp with time zone,
  last_updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT fake_detection_guides_pkey PRIMARY KEY (id),
  CONSTRAINT fake_detection_guides_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES auth.users(id),
  CONSTRAINT fake_detection_guides_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES auth.users(id)
);
CREATE TABLE public.glossary_terms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term text NOT NULL,
  definition text NOT NULL,
  status text NOT NULL DEFAULT 'pending_review'::text CHECK (status = ANY (ARRAY['published'::text, 'pending_review'::text])),
  submitted_by uuid,
  approved_by uuid,
  slug text UNIQUE,
  published_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT glossary_terms_pkey PRIMARY KEY (id),
  CONSTRAINT glossary_terms_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES auth.users(id),
  CONSTRAINT glossary_terms_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES auth.users(id)
);
CREATE TABLE public.listing_photos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL,
  file_url text NOT NULL,
  display_order integer NOT NULL CHECK (display_order >= 1 AND display_order <= 5),
  uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT listing_photos_pkey PRIMARY KEY (id),
  CONSTRAINT listing_photos_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id)
);
CREATE TABLE public.listings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sale_post_number text NOT NULL DEFAULT ('PFC-'::text || lpad((nextval('listing_sale_post_seq'::regclass))::text, 5, '0'::text)) UNIQUE,
  seller_id uuid NOT NULL,
  listing_type USER-DEFINED NOT NULL,
  fragrance_name text NOT NULL,
  brand text NOT NULL,
  size_ml numeric NOT NULL CHECK (size_ml > 0::numeric),
  condition USER-DEFINED,
  price_pkr integer NOT NULL DEFAULT 0 CHECK (price_pkr >= 0),
  delivery_details text,
  impression_declaration_accepted boolean NOT NULL DEFAULT false,
  status USER-DEFINED NOT NULL DEFAULT 'Draft'::listing_status,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  published_at timestamp with time zone,
  last_updated_at timestamp with time zone NOT NULL DEFAULT now(),
  sold_at timestamp with time zone,
  expired_at timestamp with time zone,
  deleted_at timestamp with time zone,
  removed_at timestamp with time zone,
  auction_end_at timestamp with time zone,
  quantity_available integer DEFAULT 1 CHECK (quantity_available >= 0),
  fragrance_family text,
  fragrance_notes text,
  hashtags ARRAY,
  vintage_year integer CHECK (vintage_year >= 1900 AND vintage_year <= 2100),
  condition_notes text,
  commission_rate numeric,
  commission_status text,
  transaction_value integer,
  payment_provider text,
  payment_status text,
  auction_outcome_note text CHECK (char_length(auction_outcome_note) <= 200),
  CONSTRAINT listings_pkey PRIMARY KEY (id),
  CONSTRAINT listings_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  body text NOT NULL CHECK (char_length(body) <= 1000),
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id)
);
CREATE TABLE public.otp_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_identifier text NOT NULL,
  attempt_type text NOT NULL CHECK (attempt_type = ANY (ARRAY['request'::text, 'verify'::text])),
  otp_session_id text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT otp_attempts_pkey PRIMARY KEY (id)
);
CREATE TABLE public.pickup_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL UNIQUE,
  address text NOT NULL,
  latitude numeric,
  longitude numeric,
  display_latitude numeric,
  display_longitude numeric,
  location_source USER-DEFINED NOT NULL DEFAULT 'manual'::location_source,
  visibility_consent_acknowledged boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT pickup_locations_pkey PRIMARY KEY (id),
  CONSTRAINT pickup_locations_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  role USER-DEFINED NOT NULL DEFAULT 'member'::user_role,
  account_status USER-DEFINED NOT NULL DEFAULT 'active'::account_status,
  suspended_until timestamp with time zone,
  display_name text CHECK (char_length(display_name) >= 2 AND char_length(display_name) <= 50),
  city text,
  phone_number text CHECK (phone_number ~ '^\+923[0-9]{9}$'::text),
  email_address text,
  avatar_url text,
  profile_setup_complete boolean NOT NULL DEFAULT false,
  transaction_count integer NOT NULL DEFAULT 0 CHECK (transaction_count >= 0),
  pfc_seller_code text UNIQUE,
  is_legacy_fb_seller boolean NOT NULL DEFAULT false,
  fb_seller_id text,
  fb_profile_url text,
  verified_at timestamp with time zone,
  verified_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT profiles_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id)
);
CREATE TABLE public.report_evidence (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  report_id uuid NOT NULL,
  file_url text NOT NULL,
  uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT report_evidence_pkey PRIMARY KEY (id),
  CONSTRAINT report_evidence_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id)
);
CREATE TABLE public.reports (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  case_id text NOT NULL DEFAULT ('PFC-CASE-'::text || lpad((nextval('report_case_seq'::regclass))::text, 5, '0'::text)) UNIQUE,
  reporter_id uuid NOT NULL,
  reported_user_id uuid NOT NULL,
  report_type USER-DEFINED NOT NULL,
  description text NOT NULL,
  target_listing_id uuid,
  target_review_id uuid,
  status USER-DEFINED NOT NULL DEFAULT 'Open'::report_status,
  resolution_note text,
  submitted_at timestamp with time zone NOT NULL DEFAULT now(),
  resolved_at timestamp with time zone,
  CONSTRAINT reports_pkey PRIMARY KEY (id),
  CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES auth.users(id),
  CONSTRAINT reports_reported_user_id_fkey FOREIGN KEY (reported_user_id) REFERENCES auth.users(id),
  CONSTRAINT reports_target_listing_id_fkey FOREIGN KEY (target_listing_id) REFERENCES public.listings(id),
  CONSTRAINT reports_target_review_id_fkey FOREIGN KEY (target_review_id) REFERENCES public.reviews(id)
);
CREATE TABLE public.review_photos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  review_id uuid NOT NULL,
  file_url text NOT NULL,
  uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT review_photos_pkey PRIMARY KEY (id),
  CONSTRAINT review_photos_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.reviews(id)
);
CREATE TABLE public.reviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL,
  reviewer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  rating smallint NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text NOT NULL CHECK (char_length(comment) <= 500),
  submitted_at timestamp with time zone NOT NULL DEFAULT now(),
  last_edited_at timestamp with time zone,
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_listing_id_fkey FOREIGN KEY (listing_id) REFERENCES public.listings(id),
  CONSTRAINT reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES auth.users(id),
  CONSTRAINT reviews_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES auth.users(id)
);
CREATE TABLE public.seller_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  applicant_id uuid NOT NULL,
  full_legal_name text NOT NULL,
  cnic_number text NOT NULL,
  cnic_front_url text NOT NULL,
  cnic_back_url text NOT NULL,
  phone_number text NOT NULL,
  city text NOT NULL,
  seller_types ARRAY NOT NULL,
  is_existing_fb_seller boolean NOT NULL DEFAULT false,
  fb_seller_id text,
  fb_profile_url text,
  status USER-DEFINED NOT NULL DEFAULT 'Pending'::application_status,
  rejection_reason text,
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  submitted_at timestamp with time zone NOT NULL DEFAULT now(),
  cnic_purge_at timestamp with time zone,
  CONSTRAINT seller_applications_pkey PRIMARY KEY (id),
  CONSTRAINT seller_applications_applicant_id_fkey FOREIGN KEY (applicant_id) REFERENCES auth.users(id),
  CONSTRAINT seller_applications_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)
);