import { useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import styles from './EditListingPage.module.css'

// ─── Constants ────────────────────────────────────────────────────────────────

const LISTING_TYPES = ['Full Bottle', 'Decant/Split', 'Swap', 'Auction'] as const
const CONDITIONS = ['New', 'Like New', 'Excellent', 'Good', 'Fair'] as const
const MAX_PHOTOS = 5
const MAX_PHOTO_BYTES = 10 * 1024 * 1024 // 10 MB

// ─── Types ────────────────────────────────────────────────────────────────────

interface VariantRow {
  _key: string
  size_ml: string
  price_pkr: string
  quantity_available: string
  condition: string
  condition_notes: string
  variant_notes: string
  display_order: number
}

interface FormState {
  fragrance_name: string
  brand: string
  listing_type: string
  fragrance_family: string
  fragrance_notes: string
  vintage_year: string
  condition: string
  condition_notes: string
  price_pkr: string
  size_ml: string
  quantity_available: string
  delivery_details: string
  impression_declaration_accepted: boolean
  auction_end_at: string
  hashtags: string[]
}

const emptyForm = (): FormState => ({
  fragrance_name: '',
  brand: '',
  listing_type: 'Full Bottle',
  fragrance_family: '',
  fragrance_notes: '',
  vintage_year: '',
  condition: '',
  condition_notes: '',
  price_pkr: '',
  size_ml: '',
  quantity_available: '1',
  delivery_details: '',
  impression_declaration_accepted: false,
  auction_end_at: '',
  hashtags: [],
})

function makeVariantKey() {
  return Math.random().toString(36).slice(2)
}

function emptyVariantRow(order: number): VariantRow {
  return {
    _key: makeVariantKey(),
    size_ml: '',
    price_pkr: '',
    quantity_available: '1',
    condition: '',
    condition_notes: '',
    variant_notes: '',
    display_order: order,
  }
}

// ─── Icons ────────────────────────────────────────────────────────────────────

function ArrowLeftIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M19 12H5" /><path d="M12 19l-7-7 7-7" />
    </svg>
  )
}

function PlusIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

function XIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  )
}

function CameraIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
      <circle cx="12" cy="13" r="4" />
    </svg>
  )
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function fileExt(file: File): string {
  const m = file.type.match(/image\/(\w+)/)
  return m ? m[1].replace('jpeg', 'jpg') : 'jpg'
}

// ─── CreateListingPage ────────────────────────────────────────────────────────

export function CreateListingPage() {
  const navigate = useNavigate()
  const { user } = useAuth()

  const [form, setForm] = useState<FormState>(emptyForm())
  const [variants, setVariants] = useState<VariantRow[]>([])
  const [useVariants, setUseVariants] = useState(false)
  const [photoFiles, setPhotoFiles] = useState<File[]>([])

  const [saving, setSaving] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [saveMsg, setSaveMsg] = useState<string | null>(null)

  const photoInputRef = useRef<HTMLInputElement>(null)
  const saveMsgTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  // ── Validation ─────────────────────────────────────────────────────────────

  function validate(requireDeclaration: boolean): Record<string, string> {
    const e: Record<string, string> = {}
    if (!form.fragrance_name.trim()) e.fragrance_name = 'Fragrance name is required'
    else if (form.fragrance_name.length > 120) e.fragrance_name = 'Max 120 characters'
    if (!form.brand.trim()) e.brand = 'Brand is required'
    else if (form.brand.length > 120) e.brand = 'Max 120 characters'
    if (!form.listing_type) e.listing_type = 'Listing type is required'
    if (form.listing_type === 'Auction' && !form.auction_end_at) {
      e.auction_end_at = 'Auction end time is required'
    } else if (form.listing_type === 'Auction' && new Date(form.auction_end_at) < new Date()) {
      e.auction_end_at = 'End time must be in the future'
    }
    if (form.vintage_year) {
      const y = parseInt(form.vintage_year)
      if (isNaN(y) || y < 1900 || y > new Date().getFullYear()) e.vintage_year = `Enter a year between 1900 and ${new Date().getFullYear()}`
    }
    if (useVariants) {
      if (variants.length === 0) e.variants = 'Add at least one size variant'
      variants.forEach((v, i) => {
        if (!v.size_ml) e[`variant_${i}_size_ml`] = 'Size required'
        if (!v.price_pkr) e[`variant_${i}_price_pkr`] = 'Price required'
      })
    } else {
      if (!form.price_pkr) e.price_pkr = 'Price is required'
      else if (isNaN(Number(form.price_pkr)) || Number(form.price_pkr) < 0) e.price_pkr = 'Enter a valid price'
    }
    if (photoFiles.length > MAX_PHOTOS) e.photos = `Maximum ${MAX_PHOTOS} photos allowed`
    if (requireDeclaration && !form.impression_declaration_accepted) {
      e.impression_declaration = 'You must confirm the impression declaration to publish'
    }
    return e
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  async function runCreate(publishAfter: boolean): Promise<string | null> {
    const errs = validate(publishAfter)
    setErrors(errs)
    if (Object.keys(errs).length > 0) return null

    if (!user?.id) return null

    try {
      // 1. Insert listing
      const { data: listingData, error: listErr } = await supabase
        .from('listings')
        .insert({
          seller_id: user.id,
          fragrance_name: form.fragrance_name.trim(),
          brand: form.brand.trim(),
          listing_type: form.listing_type,
          fragrance_family: form.fragrance_family.trim() || null,
          fragrance_notes: form.fragrance_notes.trim() || null,
          vintage_year: form.vintage_year ? parseInt(form.vintage_year) : null,
          condition: useVariants ? null : (form.condition || null),
          condition_notes: useVariants ? null : (form.condition_notes.trim() || null),
          price_pkr: useVariants ? 0 : parseInt(form.price_pkr) || 0,
          size_ml: useVariants ? null : (form.size_ml ? parseFloat(form.size_ml) : null),
          quantity_available: useVariants ? null : (parseInt(form.quantity_available) || 1),
          delivery_details: form.delivery_details.trim() || null,
          impression_declaration_accepted: form.impression_declaration_accepted,
          auction_end_at: form.listing_type === 'Auction' && form.auction_end_at
            ? new Date(form.auction_end_at).toISOString()
            : null,
          hashtags: form.hashtags.length > 0 ? form.hashtags : null,
          status: publishAfter ? 'Published' : 'Draft',
          ...(publishAfter ? { published_at: new Date().toISOString() } : {}),
        })
        .select('id')
        .single()

      if (listErr || !listingData) throw listErr ?? new Error('No listing returned')
      const newId: string = (listingData as any).id

      // 2. Insert variants
      if (useVariants && variants.length > 0) {
        await supabase.from('listing_variants').insert(
          variants.map((v, i) => ({
            listing_id: newId,
            size_ml: parseFloat(v.size_ml),
            price_pkr: parseInt(v.price_pkr),
            quantity_available: parseInt(v.quantity_available) || 1,
            condition: v.condition || null,
            condition_notes: v.condition_notes.trim() || null,
            variant_notes: v.variant_notes.trim() || null,
            display_order: i + 1,
          }))
        )
      }

      // 3. Upload photos
      for (let i = 0; i < photoFiles.length; i++) {
        const file = photoFiles[i]
        const ext = fileExt(file)
        const path = `${newId}/${Date.now()}-${i}.${ext}`
        const { error: upErr } = await supabase.storage.from('listing-photos').upload(path, file, {
          contentType: file.type,
          upsert: false,
        })
        if (upErr) continue
        const { data: urlData } = supabase.storage.from('listing-photos').getPublicUrl(path)
        await supabase.from('listing_photos').insert({
          listing_id: newId,
          file_url: urlData.publicUrl,
          display_order: i + 1,
        })
      }

      return newId
    } catch {
      showSaveMsg('Save failed — please try again')
      return null
    }
  }

  function showSaveMsg(msg: string) {
    setSaveMsg(msg)
    if (saveMsgTimer.current) clearTimeout(saveMsgTimer.current)
    saveMsgTimer.current = setTimeout(() => setSaveMsg(null), 3000)
  }

  async function handleSaveDraft() {
    setSaving(true)
    const newId = await runCreate(false)
    setSaving(false)
    if (newId) navigate(`/marketplace/${newId}/edit`)
  }

  async function handlePublish() {
    setPublishing(true)
    const newId = await runCreate(true)
    setPublishing(false)
    if (newId) navigate('/dashboard/listings')
  }

  // ── Photo handling ──────────────────────────────────────────────────────────

  function handlePhotoFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    const remaining = MAX_PHOTOS - photoFiles.length
    const valid = files.filter(f => {
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(f.type)) return false
      if (f.size > MAX_PHOTO_BYTES) return false
      return true
    }).slice(0, remaining)
    setPhotoFiles(prev => [...prev, ...valid])
    if (photoInputRef.current) photoInputRef.current.value = ''
  }

  function removePhoto(index: number) {
    setPhotoFiles(prev => prev.filter((_, i) => i !== index))
  }

  // ── Variant handling ────────────────────────────────────────────────────────

  function toggleVariants(on: boolean) {
    if (on) {
      const seed = emptyVariantRow(1)
      seed.size_ml = form.size_ml
      seed.price_pkr = form.price_pkr
      seed.quantity_available = form.quantity_available
      seed.condition = form.condition
      setVariants([seed])
      setUseVariants(true)
    } else {
      if (variants.length > 0) {
        setForm(f => ({
          ...f,
          size_ml: variants[0].size_ml,
          price_pkr: variants[0].price_pkr,
          quantity_available: variants[0].quantity_available,
          condition: variants[0].condition,
        }))
      }
      setVariants([])
      setUseVariants(false)
    }
  }

  function addVariantRow() {
    if (variants.length >= 10) return
    setVariants(prev => [...prev, emptyVariantRow(prev.length + 1)])
  }

  function updateVariant(key: string, field: keyof VariantRow, value: string) {
    setVariants(prev => prev.map(v => v._key === key ? { ...v, [field]: value } : v))
  }

  function removeVariantRow(key: string) {
    setVariants(prev => prev.filter(v => v._key !== key))
  }

  function setField(field: keyof FormState, value: string | boolean) {
    setForm(f => ({ ...f, [field]: value }))
    setErrors(e => { const n = { ...e }; delete n[field as string]; return n })
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  const totalPhotos = photoFiles.length

  return (
    <div className={styles.page}>
      <div className={styles.inner}>

        {/* ── Header ── */}
        <div className={styles.topBar}>
          <button className={styles.backBtn} onClick={() => navigate('/dashboard')}>
            <ArrowLeftIcon />
            Dashboard
          </button>
          <div className={styles.topBarRight}>
            <span className={`${styles.statusBadge} ${styles.statusDraft}`}>Draft</span>
          </div>
        </div>

        <h1 className={styles.pageTitle}>Create Listing</h1>

        {/* ── Fragrance Info ── */}
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Fragrance Info</h2>

          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Fragrance Name <span className={styles.req}>*</span></label>
              <input
                className={`${styles.input} ${errors.fragrance_name ? styles.inputError : ''}`}
                value={form.fragrance_name}
                onChange={e => setField('fragrance_name', e.target.value)}
                placeholder="e.g. Aventus"
                maxLength={120}
              />
              {errors.fragrance_name && <p className={styles.fieldError}>{errors.fragrance_name}</p>}
            </div>
            <div className={styles.field}>
              <label className={styles.label}>Brand <span className={styles.req}>*</span></label>
              <input
                className={`${styles.input} ${errors.brand ? styles.inputError : ''}`}
                value={form.brand}
                onChange={e => setField('brand', e.target.value)}
                placeholder="e.g. Creed"
                maxLength={120}
              />
              {errors.brand && <p className={styles.fieldError}>{errors.brand}</p>}
            </div>
          </div>

          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Listing Type <span className={styles.req}>*</span></label>
              <select
                className={`${styles.select} ${errors.listing_type ? styles.inputError : ''}`}
                value={form.listing_type}
                onChange={e => setField('listing_type', e.target.value)}
              >
                {LISTING_TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              {errors.listing_type && <p className={styles.fieldError}>{errors.listing_type}</p>}
            </div>
            <div className={styles.field}>
              <label className={styles.label}>Fragrance Family</label>
              <input
                className={styles.input}
                value={form.fragrance_family}
                onChange={e => setField('fragrance_family', e.target.value)}
                placeholder="e.g. Woody Aromatic"
              />
            </div>
          </div>

          {form.listing_type === 'Auction' && (
            <div className={styles.fieldNarrow}>
              <label className={styles.label}>Auction End Time <span className={styles.req}>*</span></label>
              <input
                className={`${styles.input} ${errors.auction_end_at ? styles.inputError : ''}`}
                type="datetime-local"
                value={form.auction_end_at}
                onChange={e => setField('auction_end_at', e.target.value)}
              />
              {errors.auction_end_at && <p className={styles.fieldError}>{errors.auction_end_at}</p>}
            </div>
          )}

          <div className={styles.fieldNarrow}>
            <label className={styles.label}>Hashtags</label>
            <input
              className={styles.input}
              value={form.hashtags.join(', ')}
              onChange={e => setForm({ ...form, hashtags: e.target.value.split(',').map(t => t.trim().toLowerCase().replace(/^#/, '')).filter(Boolean) })}
              placeholder="e.g. fresh, summer, niche"
            />
          </div>

          <div className={styles.field}>
            <label className={styles.label}>Fragrance Notes</label>
            <textarea
              className={styles.textarea}
              value={form.fragrance_notes}
              onChange={e => setField('fragrance_notes', e.target.value)}
              placeholder="Describe the scent profile — top, heart, and base notes..."
              rows={3}
            />
          </div>

          <div className={styles.fieldNarrow}>
            <label className={styles.label}>Vintage Year</label>
            <input
              className={`${styles.input} ${errors.vintage_year ? styles.inputError : ''}`}
              type="number"
              value={form.vintage_year}
              onChange={e => setField('vintage_year', e.target.value)}
              placeholder="e.g. 2019"
              min={1900}
              max={new Date().getFullYear()}
            />
            {errors.vintage_year && <p className={styles.fieldError}>{errors.vintage_year}</p>}
          </div>
        </section>

        {/* ── Pricing & Condition (non-variant mode) ── */}
        {!useVariants && (
          <section className={styles.section}>
            <h2 className={styles.sectionTitle}>Pricing &amp; Condition</h2>

            <div className={styles.row3}>
              <div className={styles.field}>
                <label className={styles.label}>Price (PKR) <span className={styles.req}>*</span></label>
                <input
                  className={`${styles.input} ${errors.price_pkr ? styles.inputError : ''}`}
                  type="number"
                  value={form.price_pkr}
                  onChange={e => setField('price_pkr', e.target.value)}
                  placeholder="0"
                  min={0}
                />
                {errors.price_pkr && <p className={styles.fieldError}>{errors.price_pkr}</p>}
              </div>
              <div className={styles.field}>
                <label className={styles.label}>Size (ml)</label>
                <input
                  className={styles.input}
                  type="number"
                  value={form.size_ml}
                  onChange={e => setField('size_ml', e.target.value)}
                  placeholder="e.g. 100"
                  min={1}
                />
              </div>
              <div className={styles.field}>
                <label className={styles.label}>Quantity</label>
                <input
                  className={styles.input}
                  type="number"
                  value={form.quantity_available}
                  onChange={e => setField('quantity_available', e.target.value)}
                  placeholder="1"
                  min={1}
                />
              </div>
            </div>

            <div className={styles.row2}>
              <div className={styles.field}>
                <label className={styles.label}>Condition</label>
                <select
                  className={styles.select}
                  value={form.condition}
                  onChange={e => setField('condition', e.target.value)}
                >
                  <option value="">— Select condition —</option>
                  {CONDITIONS.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div className={styles.field}>
                <label className={styles.label}>Condition Notes</label>
                <input
                  className={styles.input}
                  value={form.condition_notes}
                  onChange={e => setField('condition_notes', e.target.value)}
                  placeholder="Any visible wear, fill level, etc."
                />
              </div>
            </div>
          </section>
        )}

        {/* ── Size Variants ── */}
        <section className={styles.section}>
          <div className={styles.sectionTitleRow}>
            <h2 className={styles.sectionTitle}>Size Variants</h2>
            <label className={styles.toggleLabel}>
              <div
                className={`${styles.toggle} ${useVariants ? styles.toggleOn : ''}`}
                onClick={() => toggleVariants(!useVariants)}
                role="checkbox"
                aria-checked={useVariants}
                tabIndex={0}
                onKeyDown={e => e.key === 'Enter' && toggleVariants(!useVariants)}
              >
                <div className={styles.toggleThumb} />
              </div>
              <span>Enable multiple sizes &amp; prices</span>
            </label>
          </div>

          {useVariants && (
            <div className={styles.variantsWrap}>
              {errors.variants && <p className={`${styles.fieldError} ${styles.fieldErrorStandalone}`}>{errors.variants}</p>}

              {variants.map((v, i) => (
                <div key={v._key} className={styles.variantCard}>
                  <div className={styles.variantHeader}>
                    <span className={styles.variantIndex}>Size {i + 1}</span>
                    <button className={styles.variantRemoveBtn} onClick={() => removeVariantRow(v._key)} title="Remove variant">
                      <XIcon />
                    </button>
                  </div>

                  <div className={styles.row3}>
                    <div className={styles.field}>
                      <label className={styles.label}>Size (ml) <span className={styles.req}>*</span></label>
                      <input
                        className={`${styles.input} ${errors[`variant_${i}_size_ml`] ? styles.inputError : ''}`}
                        type="number"
                        value={v.size_ml}
                        onChange={e => updateVariant(v._key, 'size_ml', e.target.value)}
                        placeholder="e.g. 50"
                        min={1}
                      />
                      {errors[`variant_${i}_size_ml`] && <p className={styles.fieldError}>{errors[`variant_${i}_size_ml`]}</p>}
                    </div>
                    <div className={styles.field}>
                      <label className={styles.label}>Price (PKR) <span className={styles.req}>*</span></label>
                      <input
                        className={`${styles.input} ${errors[`variant_${i}_price_pkr`] ? styles.inputError : ''}`}
                        type="number"
                        value={v.price_pkr}
                        onChange={e => updateVariant(v._key, 'price_pkr', e.target.value)}
                        placeholder="0"
                        min={0}
                      />
                      {errors[`variant_${i}_price_pkr`] && <p className={styles.fieldError}>{errors[`variant_${i}_price_pkr`]}</p>}
                    </div>
                    <div className={styles.field}>
                      <label className={styles.label}>Quantity</label>
                      <input
                        className={styles.input}
                        type="number"
                        value={v.quantity_available}
                        onChange={e => updateVariant(v._key, 'quantity_available', e.target.value)}
                        placeholder="1"
                        min={1}
                      />
                    </div>
                  </div>

                  <div className={styles.row2}>
                    <div className={styles.field}>
                      <label className={styles.label}>Condition</label>
                      <select
                        className={styles.select}
                        value={v.condition}
                        onChange={e => updateVariant(v._key, 'condition', e.target.value)}
                      >
                        <option value="">— Select —</option>
                        {CONDITIONS.map(c => <option key={c} value={c}>{c}</option>)}
                      </select>
                    </div>
                    <div className={styles.field}>
                      <label className={styles.label}>Condition Notes</label>
                      <input
                        className={styles.input}
                        value={v.condition_notes}
                        onChange={e => updateVariant(v._key, 'condition_notes', e.target.value)}
                        placeholder="Fill level, wear, etc."
                      />
                    </div>
                  </div>

                  <div className={styles.field}>
                    <label className={styles.label}>Variant Notes</label>
                    <input
                      className={styles.input}
                      value={v.variant_notes}
                      onChange={e => updateVariant(v._key, 'variant_notes', e.target.value)}
                      placeholder="Any additional notes for this size"
                    />
                  </div>
                </div>
              ))}

              {variants.length < 10 && (
                <button className={styles.addVariantBtn} onClick={addVariantRow}>
                  <PlusIcon />
                  Add Size
                </button>
              )}
            </div>
          )}
        </section>

        {/* ── Delivery ── */}
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Delivery</h2>
          <div className={styles.field}>
            <label className={styles.label}>Delivery &amp; Shipping Notes</label>
            <textarea
              className={styles.textarea}
              value={form.delivery_details}
              onChange={e => setField('delivery_details', e.target.value)}
              placeholder="Courier services used, estimated delivery time, packaging details, COD availability, cities you ship to..."
              rows={3}
            />
          </div>
        </section>

        {/* ── Photos ── */}
        <section className={styles.section}>
          <div className={styles.sectionTitleRow}>
            <h2 className={styles.sectionTitle}>Photos</h2>
            <span className={styles.photoCount}>{totalPhotos} / {MAX_PHOTOS}</span>
          </div>

          {errors.photos && <p className={`${styles.fieldError} ${styles.fieldErrorStandalone}`}>{errors.photos}</p>}

          <div className={styles.photoGrid}>
            {photoFiles.map((file, i) => (
              <div key={i} className={styles.photoSlot}>
                <img src={URL.createObjectURL(file)} alt="" className={styles.photoImg} />
                <button className={styles.photoRemoveBtn} onClick={() => removePhoto(i)}>
                  <XIcon />
                </button>
              </div>
            ))}

            {totalPhotos < MAX_PHOTOS && (
              <button className={styles.photoAddSlot} onClick={() => photoInputRef.current?.click()}>
                <CameraIcon />
                <span>Add Photo</span>
              </button>
            )}
          </div>

          <input
            ref={photoInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            multiple
            style={{ display: 'none' }}
            onChange={handlePhotoFileChange}
          />

          <p className={styles.photoHint}>JPEG, PNG or WebP · Max 10 MB each · Up to {MAX_PHOTOS} photos</p>
        </section>

        {/* ── Impression Declaration ── */}
        <section className={styles.section}>
          <h2 className={styles.sectionTitle}>Impression Declaration</h2>
          <label className={`${styles.declarationLabel} ${errors.impression_declaration ? styles.declarationError : ''}`}>
            <input
              type="checkbox"
              className={styles.checkbox}
              checked={form.impression_declaration_accepted}
              onChange={e => setField('impression_declaration_accepted', e.target.checked)}
            />
            <span>
              I confirm that if this listing includes impression / inspired fragrances, it is clearly stated in the listing and does not misrepresent the product as an original designer fragrance. I take full responsibility for the accuracy of this listing.
            </span>
          </label>
          {errors.impression_declaration && (
            <p className={`${styles.fieldError} ${styles.fieldErrorStandalone}`}>{errors.impression_declaration}</p>
          )}
        </section>

        {/* ── Footer ── */}
        <div className={styles.footer}>
          <div />

          <div className={styles.footerRight}>
            {saveMsg && <span className={styles.saveMsg}>{saveMsg}</span>}
            <button
              className={styles.saveDraftBtn}
              onClick={handleSaveDraft}
              disabled={saving || publishing}
            >
              {saving ? 'Saving…' : 'Save Draft'}
            </button>
            <button
              className={styles.publishBtn}
              onClick={handlePublish}
              disabled={saving || publishing}
            >
              {publishing ? 'Publishing…' : 'Publish'}
            </button>
          </div>
        </div>

      </div>
    </div>
  )
}
