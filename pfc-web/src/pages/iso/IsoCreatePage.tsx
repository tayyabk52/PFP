import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { supabase } from '@/lib/supabase';
import styles from './IsoCreatePage.module.css';

export function IsoCreatePage() {
  const { session, user, loading } = useAuth();
  const navigate = useNavigate();

  // Redirect if not logged in
  useEffect(() => {
    if (!loading && !session) {
      navigate('/login');
    }
  }, [session, loading, navigate]);

  // Refs for auto-focus
  const nameInputRef = useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (nameInputRef.current && !loading) {
      nameInputRef.current.focus();
    }
  }, [loading]);

  const [formData, setFormData] = useState({
    fragrance_name: '',
    brand: '',
    size_ml: '',
    price_pkr: '',
    condition_notes: '',
  });

  const [errors, setErrors] = useState<Record<string, string | undefined>>({});
  const [globalError, setGlobalError] = useState<string | null>(null);
  const [isDrafting, setIsDrafting] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);

  if (loading || !user) {
    return null; // Will redirect or show AuthContext loading state
  }

  const validate = () => {
    const newErrors: Record<string, string> = {};
    const name = formData.fragrance_name.trim();
    const brand = formData.brand.trim();
    const size = formData.size_ml.trim();
    const price = formData.price_pkr.trim();
    const notes = formData.condition_notes.trim();

    if (!name || name.length < 2) newErrors.fragrance_name = 'Fragrance name must be at least 2 characters';
    if (!brand || brand.length < 2) newErrors.brand = 'Brand must be at least 2 characters';
    
    if (size) {
      const sizeNum = Number(size);
      if (isNaN(sizeNum) || sizeNum <= 0) newErrors.size_ml = 'Size must be a positive number';
    }

    if (price) {
      const priceNum = Number(price);
      if (isNaN(priceNum) || priceNum < 0 || !Number.isInteger(priceNum)) {
        newErrors.price_pkr = 'Budget must be a non-negative integer';
      }
    }

    if (notes && notes.length > 500) {
      newErrors.condition_notes = 'Notes cannot exceed 500 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (action: 'Draft' | 'Published') => {
    setGlobalError(null);
    if (!validate()) return;

    if (action === 'Draft') setIsDrafting(true);
    else setIsPublishing(true);

    try {
      const insertData = {
        seller_id: user.id,
        listing_type: 'ISO',
        status: action,
        fragrance_name: formData.fragrance_name.trim(),
        brand: formData.brand.trim(),
        size_ml: formData.size_ml ? Number(formData.size_ml) : null,
        price_pkr: formData.price_pkr ? Number(formData.price_pkr) : 0,
        condition_notes: formData.condition_notes.trim() || null,
        published_at: action === 'Published' ? new Date().toISOString() : null,
      };

      const { data, error } = await supabase
        .from('listings')
        .insert(insertData)
        .select()
        .single();

      if (error) throw error;

      if (action === 'Draft') {
        navigate('/dashboard/iso');
      } else {
        navigate(`/iso/${data.id}`);
      }
    } catch (err: any) {
      console.error('Error creating ISO:', err);
      setGlobalError(err.message || 'An unexpected error occurred. Please try again.');
    } finally {
      setIsDrafting(false);
      setIsPublishing(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
    // Clear field error on typing
    if (errors[e.target.name]) {
      setErrors(prev => ({ ...prev, [e.target.name]: undefined }));
    }
  };

  return (
    <div className={styles.container}>
      {globalError && (
        <div className={styles.globalError}>
          <span>{globalError}</span>
        </div>
      )}

      <div className={styles.scrollArea}>
        <div className={styles.formContainer}>
          <div className={styles.header}>
            <h1 className={styles.title}>What are you looking for?</h1>
            <p className={styles.subtitle}>Post an ISO to let sellers know you want to buy this fragrance.</p>
          </div>

          <div className={styles.formGroup}>
            <label className={styles.label} htmlFor="fragrance_name">Fragrance Name *</label>
            <input
              ref={nameInputRef}
              id="fragrance_name"
              name="fragrance_name"
              type="text"
              className={`${styles.input} ${errors.fragrance_name ? styles.inputError : ''}`}
              placeholder="e.g. Aventus"
              value={formData.fragrance_name}
              onChange={handleChange}
            />
            {errors.fragrance_name && <span className={styles.errorText}>{errors.fragrance_name}</span>}
          </div>

          <div className={styles.formGroup}>
            <label className={styles.label} htmlFor="brand">Brand *</label>
            <input
              id="brand"
              name="brand"
              type="text"
              className={`${styles.input} ${errors.brand ? styles.inputError : ''}`}
              placeholder="e.g. Creed"
              value={formData.brand}
              onChange={handleChange}
            />
            {errors.brand && <span className={styles.errorText}>{errors.brand}</span>}
          </div>

          <div className={styles.row}>
            <div className={styles.formGroup}>
              <label className={styles.label} htmlFor="size_ml">Size Requested (ml)</label>
              <input
                id="size_ml"
                name="size_ml"
                type="number"
                className={`${styles.input} ${errors.size_ml ? styles.inputError : ''}`}
                placeholder="Any"
                value={formData.size_ml}
                onChange={handleChange}
              />
              {errors.size_ml && <span className={styles.errorText}>{errors.size_ml}</span>}
            </div>

            <div className={styles.formGroup}>
              <label className={styles.label} htmlFor="price_pkr">Max Budget (PKR)</label>
              <input
                id="price_pkr"
                name="price_pkr"
                type="number"
                className={`${styles.input} ${errors.price_pkr ? styles.inputError : ''}`}
                placeholder="Flexible"
                value={formData.price_pkr}
                onChange={handleChange}
              />
              {errors.price_pkr && <span className={styles.errorText}>{errors.price_pkr}</span>}
            </div>
          </div>

          <div className={styles.formGroup}>
            <label className={styles.label} htmlFor="condition_notes">Additional Notes</label>
            <textarea
              id="condition_notes"
              name="condition_notes"
              className={`${styles.textarea} ${errors.condition_notes ? styles.inputError : ''}`}
              placeholder="Condition requirements, batch codes, vintage preference, etc."
              value={formData.condition_notes}
              onChange={handleChange}
              rows={4}
            />
            {errors.condition_notes && <span className={styles.errorText}>{errors.condition_notes}</span>}
          </div>
        </div>
      </div>

      <div className={styles.actionBar}>
        <button
          className={styles.draftBtn}
          onClick={() => handleSubmit('Draft')}
          disabled={isDrafting || isPublishing}
        >
          {isDrafting ? <div className={styles.spinner} /> : 'Save as Draft'}
        </button>
        <button
          className={styles.publishBtn}
          onClick={() => handleSubmit('Published')}
          disabled={isDrafting || isPublishing}
        >
          {isPublishing ? <div className={styles.spinnerWhite} /> : 'Publish Post'}
        </button>
      </div>
    </div>
  );
}
