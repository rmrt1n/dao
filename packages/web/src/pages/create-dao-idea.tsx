//depends if we want to implement this or not. If we do check the plugin functions and hardcode the address deployed on gorli.

import React, { useState } from 'react'
import { useSigner } from 'wagmi'
import { Signer } from 'ethers'
import { NFTPluginSetup } from './NFTPluginSetup'

export default function Page() {
    const { data: signer } = useSigner()

    const [showGovernanceFields, setShowGovernanceFields] = useState(false)
    const [daoAddress, setDaoAddress] = useState('')
    const [adminAddress, setAdminAddress] = useState('')
    const [nftAddress, setNftAddress] = useState('')

    const handleChooseGovernance = (event) => {
        const value = event.target.value
        setShowGovernanceFields(value === 'governance')
    }

    const handleClick = async () => {
        if (!signer) {
            console.log('No signer found')
            return
        }

        const nftPluginSetup = new NFTPluginSetup(daoAddress, adminAddress, nftAddress, signer as Signer)//change this if we want to implement this
        await nftPluginSetup.pluginInstall()//change this if we want to implement this
    }

    console.log('fuk', signer)

    return (<>
        <div className="min-h-screen flex">
            <div className="w-1/2 h-screen">
                <div className="mx-auto max-w-xl p-4 pt-20">
                    <h1>Create your DAO</h1>
                    <p>desc</p>
                    <div className="space-y-2">
                        <label htmlFor="name">DAO name</label>
                        <input id="name" className="block border rounded px-2 py-1 w-full" />
                    </div>
                    <div className="space-y-2">
                        <label htmlFor="summary">Summary</label>
                        <textarea id="summary" className="block border rounded px-2 py-1 w-full h-24" />
                    </div>
                    <div className="space-y-2">
                        <label htmlFor="website">Website</label>
                        <input id="website" className="block border rounded px-2 py-1 w-full" />
                    </div>
                    <div className="space-y-2">
                        <label htmlFor="governance">Choose Governance</label>
                        <select id="governance" onChange={handleChooseGovernance} className="block border rounded px-2 py-1 w-full">
                            <option value="none">None</option>
                            <option value="governance">Custom Governance</option>
                        </select>
                    </div>
                    {showGovernanceFields && (
                        <>
                            <div className="space-y-2">
                                <label htmlFor="daoAddress">DAO Address</label>
                                <input id="daoAddress" className="block border rounded px-2 py-1 w-full" value={daoAddress} onChange={(e) => setDaoAddress(e.target.value)} />
                            </div>
                            <div className="space-y-2">
                                <label htmlFor="adminAddress">Admin Address</label>
                                <input id="adminAddress" className="block border rounded px-2 py-1 w-full" value={adminAddress} onChange={(e) => setAdminAddress(e.target.value)} />
                            </div>
                            <div className="space-y-2">
                                <label htmlFor="nftAddress">NFT Address</label>
                                <input id="nftAddress" className="block border rounded px-2 py-1 w-full" value={nftAddress} onChange={(e) => setNftAddress(e.target.value)} />
                            </div>
                            <button className="bg-blue-500 text-white px-4 py-2 rounded mt-4" onClick={handleClick}>Create</button>
                        </div>
                </div>
                <div className="w-1/2 h-screen bg-gray-100">
                    <div className="mx-auto max-w-xl p-4 pt-20">
                        <h1>DAO Preview</h1>
                        <p>preview</p>
                    </div>
                </div>
            </div>
    </>)
}
