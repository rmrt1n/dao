import React from 'react'
import type { ReactElement } from 'react'
import Navbar from './Navbar'

export default function Layout({ children }: { children: ReactElement }) {
  return (<>
    <Navbar />
    <main className="min-h-[calc(100vh-64px)] p-4 bg-bg">
      <div className="xl:container mx-auto">
        { children }
      </div>
    </main>
  </>)
}
