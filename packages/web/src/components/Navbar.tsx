import React from 'react'
import Link from 'next/link'

export default function Navbar() {
  return (<>
    <header className="h-16 p-4 border-b">
      <nav className="xl:container mx-auto flex items-center justify-between">
        <Link href="/">oniondao</Link>
        <button>connect wallet</button>
      </nav>
    </header>
  </>)
}
