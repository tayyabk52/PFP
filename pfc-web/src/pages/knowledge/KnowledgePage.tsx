import styles from './KnowledgePage.module.css'

// ─── Static article data ───────────────────────────────────────────────────────

interface Article {
  index: string
  title: string
  description: string
}

const EDUCATION: Article[] = [
  { index: '01', title: 'Fragrance Families & Accords', description: 'From Florals to Orientals — understand the major fragrance families and how to navigate notes.' },
  { index: '02', title: 'Concentration Guide', description: 'EDP, EDT, Extrait — what these mean for longevity, projection, and price.' },
  { index: '03', title: 'Reading a Fragrance Pyramid', description: 'Top, heart, and base notes explained with real-world examples from the community.' },
  { index: '04', title: 'Niche vs. Designer', description: 'The difference in sourcing, ingredients, and what makes niche houses unique.' },
]

const COMMUNITY: Article[] = [
  { index: '01', title: 'Buying Safely on PFC', description: 'How to verify sellers, read listings, and protect yourself as a buyer.' },
  { index: '02', title: 'Trust & Verification System', description: 'How the PFC seller verification process works and what the badges mean.' },
  { index: '03', title: 'How ISO Works', description: 'Post an ISO, receive offers from verified sellers, and close the deal with confidence.' },
  { index: '04', title: 'Community Guidelines', description: 'Respect, authenticity, and the standards that keep our community trustworthy.' },
]

const SELLING: Article[] = [
  { index: '01', title: 'Seller Handbook', description: 'Everything you need to know about becoming a verified seller on PFC.' },
  { index: '02', title: 'How to Write a Great Listing', description: 'Photos, descriptions, and details that build buyer confidence and drive sales.' },
  { index: '03', title: 'Pricing Your Collection', description: 'Market comps, condition grades, and setting fair prices for your frags.' },
  { index: '04', title: 'Shipping & Packaging', description: 'Packing fragrance safely for transit and handling buyer expectations.' },
]

// ─── ArticleCard ───────────────────────────────────────────────────────────────

function ArticleCard({ article }: { article: Article }) {
  return (
    <div className={styles.articleCard}>
      <span className={styles.articleIndex}>{article.index}</span>
      <div className={styles.articleBody}>
        <h3 className={styles.articleTitle}>{article.title}</h3>
        <p className={styles.articleDesc}>{article.description}</p>
      </div>
      <div className={styles.articleArrow} aria-hidden="true">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </div>
    </div>
  )
}

// ─── KnowledgePage ─────────────────────────────────────────────────────────────

export function KnowledgePage() {
  return (
    <div className={styles.page}>
      {/* Hero */}
      <div className={styles.hero}>
        <p className={styles.heroLabel}>Knowledge Base</p>
        <h1 className={styles.heroTitle}>The Olfactory Archive</h1>
        <p className={styles.heroSub}>
          Guides, education, and community wisdom for Pakistani fragrance enthusiasts.
        </p>
      </div>

      {/* Sections */}
      <div className={styles.sections}>
        {/* Fragrance Education */}
        <section className={styles.section}>
          <div className={styles.sectionHeader}>
            <p className={styles.sectionLabel}>Education</p>
            <h2 className={styles.sectionTitle}>Fragrance Fundamentals</h2>
          </div>
          <div className={styles.articleList}>
            {EDUCATION.map(a => <ArticleCard key={a.index} article={a} />)}
          </div>
        </section>

        {/* Community Guides */}
        <section className={styles.section}>
          <div className={styles.sectionHeader}>
            <p className={styles.sectionLabel}>Community</p>
            <h2 className={styles.sectionTitle}>Buying & Community</h2>
          </div>
          <div className={styles.articleList}>
            {COMMUNITY.map(a => <ArticleCard key={a.index} article={a} />)}
          </div>
        </section>

        {/* Selling */}
        <section className={styles.section}>
          <div className={styles.sectionHeader}>
            <p className={styles.sectionLabel}>Selling</p>
            <h2 className={styles.sectionTitle}>Sell on PFC</h2>
          </div>
          <div className={styles.articleList}>
            {SELLING.map(a => <ArticleCard key={a.index} article={a} />)}
          </div>
        </section>
      </div>
    </div>
  )
}
