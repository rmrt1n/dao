import type { ReactElement } from 'react'
import type { NextPageWithLayout } from './_app'
import Link from 'next/link'
import Layout from '@/components/Layout'

const Page: NextPageWithLayout = () => {
  return (<>
    <div className="space-y-6">
      <div className="space-y-4">
        <h1>Empowering University Clubs Though DAOs</h1>
        <div className="flex flex-col lg:flex-row gap-4">
          <Link href="/create-dao">
            <div className="border p-4 rounded-sm w-full space-y-4">
              <h3>Create your own DAO</h3>
              <p>Ready to take your university club to the next level? With ClubDAO, you can establish a decentralized autonomous organization (DAO) tailored to your club's unique needs. Seamlessly collaborate, govern, and foster a stronger sense of community.</p>
              <button className="px-4 py-2 flex items-center justify-center font-medium w-full bg-blue-400 text-white rounded">Create DAO</button>
            </div>
          </Link>
          <div className="border p-4 rounded-sm w-full space-y-4">
            <h3>Join a DAO of DAOs</h3>
            <p>Want to collaborate and organize events with other university DAOs? ClubDAO's DAO of DAOs provides a unique opportunity for DAOs to synergize efforts, amplify their impact, and tackle larger-scale challenges together.</p>
            <button className="px-4 py-2 flex items-center justify-center font-medium w-full bg-blue-400 text-white rounded">Create a DAO of DAOs</button>
          </div>
          <div className="border p-4 rounded-sm w-full space-y-4">
            <h3>Learn More</h3>
            <p>Curious to dive deeper into the concept of DAOs and their potential impacts on your university club? Click here to learn about ClubDao, how it works, and how you can use our platform to enhance your organization experience.</p>
            <button className="px-4 py-2 flex items-center justify-center font-medium w-full bg-blue-400 text-white rounded">Learn More</button>
          </div>
        </div>
      </div>
      <div className="space-y-4">
        <h2>DAOs You're Apart Of</h2>
        <div className="flex gap-4">
          <Link href={`/daos/apubcc`}>
            <div className="border p-4 rounded-sm space-y-2 flex gap-4">
              <div className="h-16 w-16 rounded-full bg-gray-300" />
              <div>
                <h3>APUBCC</h3>
                <p>Official DAO of APU's Blockchain and Cryptocurrency club</p>
              </div>
            </div>
          </Link>
        </div>
      </div>
      <div className="flex gap-6">
        <div className="w-full space-y-4">
          <h2>Explore DAOs</h2>
          <div className="flex flex-col gap-4">
            { [1, 2, 3, 4, 5].map((i) => (<>
              <Link href={`/daos/${i}`}>
                <div className="border p-4 rounded-sm space-y-2 flex gap-4">
                  <div className="h-16 w-16 rounded-full bg-gray-300" />
                  <div>
                    <h3>Sample DAO {i}</h3>
                    <p>Description goes here</p>
                  </div>
                </div>
              </Link>
            </>))}
          </div>
        </div>
        <div className="max-w-md w-full space-y-4">
          <h2>filters</h2>
          <div className="border h-full bg-gray-300">
          </div>
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
