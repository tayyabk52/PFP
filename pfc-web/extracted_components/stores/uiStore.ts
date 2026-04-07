import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { Theme } from '@/types'
import { STORAGE_KEYS } from '@/constants'

interface UIState {
  isMobileMenuOpen: boolean
  sidebarCollapsed: boolean
  theme: Theme
  toggleMobileMenu: () => void
  closeMobileMenu: () => void
  toggleSidebar: () => void
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      isMobileMenuOpen: false,
      sidebarCollapsed: false,
      theme: 'dark',

      toggleMobileMenu: () => {
        set((state) => ({ isMobileMenuOpen: !state.isMobileMenuOpen }))
      },

      closeMobileMenu: () => {
        set({ isMobileMenuOpen: false })
      },

      toggleSidebar: () => {
        set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed }))
      },

      setTheme: (theme) => {
        set({ theme })
        if (theme === 'dark') {
          document.documentElement.classList.add('dark')
        } else {
          document.documentElement.classList.remove('dark')
        }
      },

      toggleTheme: () => {
        set((state) => {
          const newTheme = state.theme === 'light' ? 'dark' : 'light'
          if (newTheme === 'dark') {
            document.documentElement.classList.add('dark')
          } else {
            document.documentElement.classList.remove('dark')
          }
          return { theme: newTheme }
        })
      },
    }),
    {
      name: STORAGE_KEYS.THEME,
      partialize: (state) => ({ theme: state.theme, sidebarCollapsed: state.sidebarCollapsed }),
      onRehydrateStorage: () => (state) => {
        if (state?.theme === 'dark') {
          document.documentElement.classList.add('dark')
        }
      },
    }
  )
)
