/**
 * PostGIS geography parsing and serialization utilities.
 *
 * Supabase returns geography columns as hex-encoded EWKB strings.
 * These helpers convert between that format and plain {lat, lng} objects.
 *
 * If your backend returns coordinates differently (e.g. plain JSON),
 * you only need the parseGeoPoint() function — it handles GeoJSON and
 * plain {lat, lng} objects too.
 */

/**
 * Parse a hex EWKB string (PostGIS output) into {lat, lng}.
 * EWKB for a Point with SRID=4326 is at least 50 hex chars (25 bytes).
 */
function parseHexWKB(hex: string): { lat: number; lng: number } | null {
  if (hex.length < 50) return null
  try {
    const bytes = new Uint8Array(hex.length / 2)
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16)
    }
    const view = new DataView(bytes.buffer)
    const littleEndian = bytes[0] === 1
    // Check if SRID flag is set (0x20000000 in the type word)
    const hasSRID = (view.getUint32(1, littleEndian) & 0x20000000) !== 0
    const offset = hasSRID ? 9 : 5
    const lng = view.getFloat64(offset, littleEndian)
    const lat = view.getFloat64(offset + 8, littleEndian)
    if (isFinite(lat) && isFinite(lng)) return { lat, lng }
    return null
  } catch {
    return null
  }
}

/**
 * Parse a PostGIS geography value that may arrive as:
 *   1. Hex EWKB string:  "0101000020E6100000..."
 *   2. GeoJSON object:   { type: "Point", coordinates: [lng, lat] }
 *   3. Plain object:     { lat: number, lng: number }
 *   4. null / undefined
 */
export function parseGeoPoint(value: unknown): { lat: number; lng: number } | null {
  if (value == null) return null

  // Hex EWKB string
  if (typeof value === 'string') {
    if (/^[0-9a-fA-F]+$/.test(value)) {
      return parseHexWKB(value)
    }
    return null
  }

  if (typeof value !== 'object') return null

  const obj = value as Record<string, unknown>

  // GeoJSON Point: { type: "Point", coordinates: [lng, lat] }
  if (obj.type === 'Point' && Array.isArray(obj.coordinates)) {
    const coords = obj.coordinates as number[]
    if (coords.length >= 2 && isFinite(coords[0]) && isFinite(coords[1])) {
      return { lat: coords[1], lng: coords[0] }
    }
    return null
  }

  // Plain { lat, lng }
  if (typeof obj.lat === 'number' && typeof obj.lng === 'number') {
    return { lat: obj.lat, lng: obj.lng }
  }

  return null
}

/**
 * Serialize a {lat, lng} point to EWKT for PostgREST geography column inserts.
 * Only needed if you're writing locations back to a Supabase PostGIS column.
 */
export function toPostgisPoint(point: { lat: number; lng: number }): string {
  return `SRID=4326;POINT(${point.lng} ${point.lat})`
}
