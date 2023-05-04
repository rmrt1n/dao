import type { ReactElement } from 'react'
import type { NextPageWithLayout } from './_app'
import Link from 'next/link'
import Layout from '@/components/Layout'

const Page: NextPageWithLayout = () => {
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
        { [1, 2].map((i) => (<>
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
          { [1, 2, 3, 4, 5].map((i) => (<>
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
