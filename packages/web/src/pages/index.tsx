import type { ReactElement } from 'react'
import type { NextPageWithLayout } from './_app'
import Link from 'next/link'
import Layout from '@/components/Layout'
import { useWeb3React } from '@web3-react/core'
import { injected } from '@/lib/connectors'

const Page: NextPageWithLayout = () => {
  const { account, activate } = useWeb3React()

  const handleConnectWallet = async () => {
    try {
      await activate(injected)
    } catch (ex) {
      console.error(ex)
    }
  }

  return (<>
    <div>
      <h1>product tagline</h1>
      <div className="flex gap-4">
        <Link href="/create-dao">
          <div className="border p-4">
            <p>create dao</p>
          </div>
        </Link>
        <div className="border p-4">
          <p>create daooo</p>
        </div>
        <div className="border p-4">
          <p>learn more</p>
        </div>
      </div>
    </div>
    <div>
      <h2>daos u're apart of</h2>
      <div className="flex gap-4">
        {[1, 2].map((i) => (<>
          <Link href={`/daos/${i}`}>
            <div className="border p-4">
              <p>dao name</p>
            </div>
          </Link>
        </>))}
      </div>
    </div>
    <div className="flex gap-6">
      <div className="w-full">
        <h2>explore daos</h2>
        <div className="flex flex-col gap-4">
          {[1, 2, 3, 4, 5].map((i) => (<>
            <Link href={`/daos/${i}`}>
              <div className="border p-4">
                <p>dao name</p>
              </div>
            </Link>
          </>))}
        </div>
      </div>
      <div className="max-w-md w-full">
        <h2>filters</h2>
        <div className="border h-full">
          {!account ? (
            <button
              onClick={handleConnectWallet}
              className="bg-blue-500 text-white px-4 py-2 rounded font-medium"
            >
              Connect Wallet
            </button>
          ) : (
            <div className="text-center">
              <p className="text-gray-500">Connected with Metamask</p>
              <p>{account}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  </>)
}

Page.getLayout = (page: ReactElement) => {
  return (
    <Layout>{page}</Layout>
  )
}

export default Page;
