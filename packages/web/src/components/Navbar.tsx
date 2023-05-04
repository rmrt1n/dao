import React from 'react'
import Link from 'next/link'
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
    <header className="h-16 p-4 border-b bg-bg">
      <nav className="xl:container mx-auto flex items-center justify-between">
        <Link href="/">oniondao</Link>
        <button onClick={handleClick}>{ isConnected ? 'disconnect' : 'connect wallet' }</button>
      </nav>
    </header>
  </>)
}
