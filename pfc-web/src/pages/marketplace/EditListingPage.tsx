import { useEffect, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/context/AuthContext'
import styles from './EditListingPage.module.css'

// ─── Constants ────────────────────────────────────────────────────────────────

const LISTING_TYPES = ['Full Bottle', 'Decant/Split', 'Swap', 'Auction'] as const
const CONDITIONS = ['New', 'Like New', 'Excellent', 'Good', 'Fair'] as const
const MAX_PHOTOS = 5
const MAX_PHOTO_BYTES = 10 * 1024 * 1024 // 10 MB

// ─── Types ────────────────────────────────────────────────────────────────────

interface ExistingPhoto {
  id: string
  file_url: string
  display_order: number
}

interface VariantRow {
  _key: string           // stable UI key
  id: string | null      // null = not yet in DB
  size_ml: string
  price_pkr: string
  quantity_available: string
  condition: string
  condition_notes: string
  variant_notes: string
  display_order: number
  _toDelete: boolean
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
    id: null,
    size_ml: '',
    price_pkr: '',
    quantity_available: '1',
    condition: '',
    condition_notes: '',
    variant_notes: '',
    display_order: order,
    _toDelete: false,
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

function storagePathFromUrl(url: string): string {
  // Extract path after "/listing-photos/"
  const marker = '/listing-photos/'
  const idx = url.indexOf(marker)
  if (idx === -1) return ''
  return decodeURIComponent(url.slice(idx + marker.length).split('?')[0])
}

function fileExt(file: File): string {
  const m = file.type.match(/image\/(\w+)/)
  return m ? m[1].replace('jpeg', 'jpg') : 'jpg'
}

// ─── EditListingPage ──────────────────────────────────────────────────────────

export function EditListingPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()

  // Core state
  const [form, setForm] = useState<FormState>(emptyForm())
  const [salePostNumber, setSalePostNumber] = useState('')
  const [listingStatus, setListingStatus] = useState('')
  const [variants, setVariants] = useState<VariantRow[]>([])
  const [useVariants, setUseVariants] = useState(false)
  const [existingPhotos, setExistingPhotos] = useState<ExistingPhoto[]>([])
  const [newPhotoFiles, setNewPhotoFiles] = useState<File[]>([])
  const [deletedPhotoIds, setDeletedPhotoIds] = useState<string[]>([])

  // UI state
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [saveMsg, setSaveMsg] = useState<string | null>(null)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

  const photoInputRef = useRef<HTMLInputElement>(null)
  const saveMsgTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  // ── Load ────────────────────────────────────────────────────────────────────

  useEffect(() => {
    if (!id || !user?.id) return
    async function load() {
      setLoading(true)
      const { data, error } = await supabase
        .from('listings')
        .select(`
          id, sale_post_number, seller_id, listing_type, fragrance_name, brand,
          size_ml, condition, price_pkr, delivery_details, status, fragrance_family,
          fragrance_notes, vintage_year, condition_notes, quantity_available,
          impression_declaration_accepted, auction_end_at, hashtags,
          listing_photos(id, file_url, display_order),
          listing_variants(id, size_ml, price_pkr, quantity_available, condition, condition_notes, variant_notes, display_order)
        `)
        .eq('id', id)
        .single()

      if (error || !data) { navigate('/dashboard/listings'); return }
      // Ownership guard
      if ((data as any).seller_id !== user!.id) { navigate('/dashboard/listings'); return }

      const d = data as any
      setForm({
        fragrance_name: d.fragrance_name ?? '',
        brand: d.brand ?? '',
        listing_type: d.listing_type ?? 'Full Bottle',
        fragrance_family: d.fragrance_family ?? '',
        fragrance_notes: d.fragrance_notes ?? '',
        vintage_year: d.vintage_year != null ? String(d.vintage_year) : '',
        condition: d.condition ?? '',
        condition_notes: d.condition_notes ?? '',
        price_pkr: d.price_pkr != null ? String(d.price_pkr) : '',
        size_ml: d.size_ml != null ? String(d.size_ml) : '',
        quantity_available: d.quantity_available != null ? String(d.quantity_available) : '1',
        delivery_details: d.delivery_details ?? '',
        impression_declaration_accepted: d.impression_declaration_accepted ?? false,
        auction_end_at: d.auction_end_at ? new Date(d.auction_end_at).toISOString().slice(0, 16) : '',
        hashtags: d.hashtags ?? [],
      })
      setSalePostNumber(d.sale_post_number ?? '')
      setListingStatus(d.status ?? 'Draft')

      const photos: ExistingPhoto[] = [...(d.listing_photos ?? [])]
        .sort((a: any, b: any) => a.display_order - b.display_order)
      setExistingPhotos(photos)

      const varRows: VariantRow[] = [...(d.listing_variants ?? [])]
        .sort((a: any, b: any) => a.display_order - b.display_order)
        .map((v: any) => ({
          _key: makeVariantKey(),
          id: v.id,
          size_ml: v.size_ml != null ? String(v.size_ml) : '',
          price_pkr: v.price_pkr != null ? String(v.price_pkr) : '',
          quantity_available: v.quantity_available != null ? String(v.quantity_available) : '1',
          condition: v.condition ?? '',
          condition_notes: v.condition_notes ?? '',
          variant_notes: v.variant_notes ?? '',
          display_order: v.display_order,
          _toDelete: false,
        }))
      setVariants(varRows)
      setUseVariants(varRows.length > 0)
      setLoading(false)
    }
    load()
  }, [id, user?.id, navigate])

  // ── Validation ──────────────────────────────────────────────────────────────

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
    const activeVariants = variants.filter(v => !v._toDelete)
    if (useVariants) {
      if (activeVariants.length === 0) e.variants = 'Add at least one size variant'
      activeVariants.forEach((v, i) => {
        if (!v.size_ml) e[`variant_${i}_size_ml`] = 'Size required'
        if (!v.price_pkr) e[`variant_${i}_price_pkr`] = 'Price required'
      })
    } else {
      if (!form.price_pkr) e.price_pkr = 'Price is required'
      else if (isNaN(Number(form.price_pkr)) || Number(form.price_pkr) < 0) e.price_pkr = 'Enter a valid price'
    }
    const totalPhotos = existingPhotos.length + newPhotoFiles.length
    if (totalPhotos > MAX_PHOTOS) e.photos = `Maximum ${MAX_PHOTOS} photos allowed`
    if (requireDeclaration && !form.impression_declaration_accepted) {
      e.impression_declaration = 'You must confirm the impression declaration to publish'
    }
    return e
  }

  // ── Save ops ────────────────────────────────────────────────────────────────

  async function runSave(): Promise<boolean> {
    const errs = validate(false)
    setErrors(errs)
    if (Object.keys(errs).length > 0) return false

    setSaving(true)
    try {
      // 1. Update listing core fields
      const activeVariants = variants.filter(v => !v._toDelete)
      const { error: listErr } = await supabase.from('listings').update({
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
        auction_end_at: form.listing_type === 'Auction' && form.auction_end_at ? new Date(form.auction_end_at).toISOString() : null,
        hashtags: form.hashtags.length > 0 ? form.hashtags : null,
        last_updated_at: new Date().toISOString(),
      }).eq('id', id!)

      if (listErr) throw listErr

      // 2. Sync variants
      const toDelete = variants.filter(v => v._toDelete && v.id)
      const toInsert = activeVariants.filter(v => !v.id)
      const toUpdate = activeVariants.filter(v => !!v.id)

      for (const v of toDelete) {
        await supabase.from('listing_variants').delete().eq('id', v.id!)
      }
      if (toInsert.length > 0) {
        await supabase.from('listing_variants').insert(
          toInsert.map((v, i) => ({
            listing_id: id!,
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
      for (const v of toUpdate) {
        const idx = activeVariants.indexOf(v)
        await supabase.from('listing_variants').update({
          size_ml: parseFloat(v.size_ml),
          price_pkr: parseInt(v.price_pkr),
          quantity_available: parseInt(v.quantity_available) || 1,
          condition: v.condition || null,
          condition_notes: v.condition_notes.trim() || null,
          variant_notes: v.variant_notes.trim() || null,
          display_order: idx + 1,
        }).eq('id', v.id!)
      }

      // 3. Delete removed photos
      for (const photoId of deletedPhotoIds) {
        const photo = existingPhotos.find(p => p.id === photoId)
        if (photo) {
          const path = storagePathFromUrl(photo.file_url)
          if (path) await supabase.storage.from('listing-photos').remove([path])
        }
        await supabase.from('listing_photos').delete().eq('id', photoId)
      }
      setDeletedPhotoIds([])

      // 4. Upload new photos
      const currentCount = existingPhotos.filter(p => !deletedPhotoIds.includes(p.id)).length
      for (let i = 0; i < newPhotoFiles.length; i++) {
        const file = newPhotoFiles[i]
        const ext = fileExt(file)
        const path = `${id}/${Date.now()}-${i}.${ext}`
        const { error: upErr } = await supabase.storage.from('listing-photos').upload(path, file, {
          contentType: file.type,
          upsert: false,
        })
        if (upErr) continue
        const { data: urlData } = supabase.storage.from('listing-photos').getPublicUrl(path)
        await supabase.from('listing_photos').insert({
          listing_id: id!,
          file_url: urlData.publicUrl,
          display_order: currentCount + i + 1,
        })
      }
      setNewPhotoFiles([])

      // 5. Reload photos + variants fresh from DB
      const { data: fresh } = await supabase
        .from('listings')
        .select('listing_photos(id, file_url, display_order), listing_variants(id, size_ml, price_pkr, quantity_available, condition, condition_notes, variant_notes, display_order)')
        .eq('id', id!)
        .single()

      if (fresh) {
        const freshPhotos: ExistingPhoto[] = [...((fresh as any).listing_photos ?? [])]
          .sort((a: any, b: any) => a.display_order - b.display_order)
        setExistingPhotos(freshPhotos)

        const freshVars: VariantRow[] = [...((fresh as any).listing_variants ?? [])]
          .sort((a: any, b: any) => a.display_order - b.display_order)
          .map((v: any) => ({
            _key: makeVariantKey(),
            id: v.id,
            size_ml: String(v.size_ml ?? ''),
            price_pkr: String(v.price_pkr ?? ''),
            quantity_available: String(v.quantity_available ?? '1'),
            condition: v.condition ?? '',
            condition_notes: v.condition_notes ?? '',
            variant_notes: v.variant_notes ?? '',
            display_order: v.display_order,
            _toDelete: false,
          }))
        setVariants(freshVars)
      }

      showSaveMsg('Changes saved')
      return true
    } catch {
      showSaveMsg('Save failed — please try again')
      return false
    } finally {
      setSaving(false)
    }
  }

  function showSaveMsg(msg: string) {
    setSaveMsg(msg)
    if (saveMsgTimer.current) clearTimeout(saveMsgTimer.current)
    saveMsgTimer.current = setTimeout(() => setSaveMsg(null), 3000)
  }

  // ── Publish ─────────────────────────────────────────────────────────────────

  async function handlePublish() {
    const errs = validate(true)
    setErrors(errs)
    if (Object.keys(errs).length > 0) return

    setPublishing(true)
    const saved = await runSave()
    if (!saved) { setPublishing(false); return }

    const { error } = await supabase.from('listings').update({
      status: 'Published',
      published_at: new Date().toISOString(),
    }).eq('id', id!)

    if (!error) {
      setListingStatus('Published')
      showSaveMsg('Listing published')
    } else {
      showSaveMsg('Publish failed — please try again')
    }
    setPublishing(false)
  }

  async function handleUnpublish() {
    setPublishing(true)
    const { error } = await supabase.from('listings').update({ status: 'Draft' }).eq('id', id!)
    if (!error) {
      setListingStatus('Draft')
      showSaveMsg('Listing unpublished')
    }
    setPublishing(false)
  }

  async function handleDelete() {
    setDeleting(true)
    await supabase.from('listings').update({
      status: 'Deleted',
      deleted_at: new Date().toISOString(),
    }).eq('id', id!)
    navigate('/dashboard/listings')
  }

  // ── Photo handling ──────────────────────────────────────────────────────────

  function handlePhotoFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    const remaining = MAX_PHOTOS - existingPhotos.length - newPhotoFiles.length
    const valid = files.filter(f => {
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(f.type)) return false
      if (f.size > MAX_PHOTO_BYTES) return false
      return true
    }).slice(0, remaining)

    setNewPhotoFiles(prev => [...prev, ...valid])
    if (photoInputRef.current) photoInputRef.current.value = ''
  }

  function removeExistingPhoto(photoId: string) {
    setExistingPhotos(prev => prev.filter(p => p.id !== photoId))
    setDeletedPhotoIds(prev => [...prev, photoId])
  }

  function removeNewPhoto(index: number) {
    setNewPhotoFiles(prev => prev.filter((_, i) => i !== index))
  }

  // ── Variant handling ────────────────────────────────────────────────────────

  function toggleVariants(on: boolean) {
    if (on) {
      // Seed first row from parent values
      const seed = emptyVariantRow(1)
      seed.size_ml = form.size_ml
      seed.price_pkr = form.price_pkr
      seed.quantity_available = form.quantity_available
      seed.condition = form.condition
      setVariants([seed])
      setUseVariants(true)
    } else {
      // Move first active variant values back to parent, mark all for deletion
      const active = variants.filter(v => !v._toDelete)
      if (active.length > 0) {
        setForm(f => ({
          ...f,
          size_ml: active[0].size_ml,
          price_pkr: active[0].price_pkr,
          quantity_available: active[0].quantity_available,
          condition: active[0].condition,
        }))
      }
      setVariants(prev => prev.map(v => ({ ...v, _toDelete: true })))
      setUseVariants(false)
    }
  }

  function addVariantRow() {
    const active = variants.filter(v => !v._toDelete)
    if (active.length >= 10) return
    setVariants(prev => [...prev, emptyVariantRow(prev.length + 1)])
  }

  function updateVariant(key: string, field: keyof VariantRow, value: string) {
    setVariants(prev => prev.map(v => v._key === key ? { ...v, [field]: value } : v))
  }

  function removeVariantRow(key: string) {
    setVariants(prev => prev.map(v => v._key === key ? { ...v, _toDelete: true } : v))
  }

  function setField(field: keyof FormState, value: string | boolean) {
    setForm(f => ({ ...f, [field]: value }))
    setErrors(e => { const n = { ...e }; delete n[field as string]; return n })
  }

  // ── Render ──────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className={styles.spinnerPage}>
        <div className={styles.spinner} />
      </div>
    )
  }

  const totalPhotos = existingPhotos.length + newPhotoFiles.length
  const activeVariants = variants.filter(v => !v._toDelete)
  const isPublished = listingStatus === 'Published'

  return (
    <div className={styles.page}>
      <div className={styles.inner}>

        {/* ── Header ── */}
        <div className={styles.topBar}>
          <button className={styles.backBtn} onClick={() => navigate('/dashboard/listings')}>
            <ArrowLeftIcon />
            My Listings
          </button>
          <div className={styles.topBarRight}>
            <span className={`${styles.statusBadge} ${isPublished ? styles.statusPublished : styles.statusDraft}`}>
              {listingStatus}
            </span>
            {salePostNumber && (
              <span className={styles.postNumber}>{salePostNumber}</span>
            )}
          </div>
        </div>

        <h1 className={styles.pageTitle}>Edit Listing</h1>

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

              {activeVariants.map((v, i) => (
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

              {activeVariants.length < 10 && (
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
            {/* Existing photos */}
            {existingPhotos.map(photo => (
              <div key={photo.id} className={styles.photoSlot}>
                <img src={photo.file_url} alt="" className={styles.photoImg} />
                <button className={styles.photoRemoveBtn} onClick={() => removeExistingPhoto(photo.id)}>
                  <XIcon />
                </button>
              </div>
            ))}

            {/* New (staged) photos */}
            {newPhotoFiles.map((file, i) => (
              <div key={i} className={styles.photoSlot}>
                <img src={URL.createObjectURL(file)} alt="" className={styles.photoImg} />
                <button className={styles.photoRemoveBtn} onClick={() => removeNewPhoto(i)}>
                  <XIcon />
                </button>
                <span className={styles.photoNewBadge}>New</span>
              </div>
            ))}

            {/* Empty add slot */}
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
          <button
            className={styles.deleteBtn}
            onClick={() => setShowDeleteConfirm(true)}
            disabled={deleting}
          >
            Delete Listing
          </button>

          <div className={styles.footerRight}>
            {saveMsg && <span className={styles.saveMsg}>{saveMsg}</span>}
            <button
              className={styles.saveDraftBtn}
              onClick={runSave}
              disabled={saving || publishing}
            >
              {saving ? 'Saving…' : 'Save Draft'}
            </button>
            {isPublished ? (
              <button
                className={styles.unpublishBtn}
                onClick={handleUnpublish}
                disabled={publishing}
              >
                {publishing ? 'Updating…' : 'Unpublish'}
              </button>
            ) : (
              <button
                className={styles.publishBtn}
                onClick={handlePublish}
                disabled={saving || publishing}
              >
                {publishing ? 'Publishing…' : 'Publish'}
              </button>
            )}
          </div>
        </div>

        {/* ── Delete Confirm Dialog ── */}
        {showDeleteConfirm && (
          <div className={styles.dialogOverlay}>
            <div className={styles.dialog}>
              <h3 className={styles.dialogTitle}>Delete Listing?</h3>
              <p className={styles.dialogBody}>
                This will remove the listing from the marketplace. This action cannot be undone.
              </p>
              <div className={styles.dialogActions}>
                <button className={styles.dialogCancel} onClick={() => setShowDeleteConfirm(false)}>
                  Cancel
                </button>
                <button className={styles.dialogConfirm} onClick={handleDelete} disabled={deleting}>
                  {deleting ? 'Deleting…' : 'Yes, Delete'}
                </button>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  )
}
