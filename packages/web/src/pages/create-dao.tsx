import React from 'react'
import { useSigner } from 'wagmi'
import { Client } from '@aragon/sdk-client'
import { context } from '@/lib/aragon'
import { Signer } from 'ethers'

export default function Page() {
  const { data: signer } = useSigner()

  // context.set({ signer: signer as Signer })
  // const client = new Client(context)
  console.log('fuk', signer)

  return (<>
    <div className="min-h-screen flex">
      <div className="w-1/2 h-screen">
        <div className="mx-auto max-w-xl p-4 pt-20">
          <h1>Create your DAO</h1>
          <p>desc</p>
          <div className="space-y-2">
            <label htmlFor="name">DAO name</label>
            <input id="name" className="block border rounded px-2 py-1 w-full"/>
          </div>
          <div className="space-y-2">
            <label htmlFor="summary">Summary</label>
            <textarea id="summary" className="block border rounded px-2 py-1 w-full h-24"/>
          </div>
          <div className="space-y-2">
            <label htmlFor="website">Website</label>
            <input id="website" className="block border rounded px-2 py-1 w-full"/>
          </div>
          <button className="px-4 py-2 rounded border flex items-center justify-center w-full ">Continue</button>
        </div>
      </div>
      <div className="w-1/2 bg-gray-400 h-screen">
      </div>
    </div>
  </>)
}
