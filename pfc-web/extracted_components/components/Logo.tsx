import { Leaf } from 'lucide-react'
import { cn } from '@/lib/utils'

interface LogoProps {
  className?: string
  showText?: boolean
}

export function Logo({ className, showText = true }: LogoProps) {
  return (
    <div className={cn('flex items-center gap-3', className)}>
      <Leaf className="h-6 w-6 text-primary" strokeWidth={1.5} />
      {showText && (
        <span className="text-2xl font-serif font-semibold tracking-wide text-foreground uppercase">
          GCEH
        </span>
      )}
    </div>
  )
}
