import React from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'
import { context } from '@/lib/aragon'

export default function Navbar() {
  const { isConnected } = useAccount()
  const { connect } = useConnect({
    connector: new InjectedConnector(),
  })
  const { disconnect } = useDisconnect()

  const handleClick = () => {
    return isConnected 
      ? disconnect() 
      : () => {
        connect()
      }
  }

  return (<>
    <header className="h-18 p-4 border-b bg-bg">
      <nav className="xl:container mx-auto flex items-center justify-between">
        <Link href="/">
          <div className="relative w-32 h-8">
            <Image src="/images/CLUBDAO.jpg" alt="clubdao logo" fill />
          </div>
        </Link>
        <button className="px-4 py-2 flex items-center justify-center font-medium bg-blue-400 text-white rounded" onClick={handleClick}>{ isConnected ? 'disconnect' : 'connect wallet' }</button>
      </nav>
    </header>
  </>)
}
