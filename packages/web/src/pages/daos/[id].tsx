import type { ReactElement } from 'react'
import type { NextPageWithLayout } from '@/pages/_app'
import { useRouter } from 'next/router'
import Layout from '@/components/Layout'

const Page: NextPageWithLayout = () => {
  const router = useRouter()
  const { id } = router.query

  return (<>
    <h1>name of dao { id }</h1>
    <div>
      <div className="flex items-center justify-between">
        <h2>about</h2>
        <div className="space-x-4">
          <button>settings</button>
          <button>create proposal</button>
        </div>
      </div>
      <p className="max-w-2xl">description</p>
    </div>
    <div className="flex gap-6">
      <div className="w-full">
        <h2>proposals</h2>
        <div className="flex flex-col gap-4">
          { [1, 2, 3, 4, 5].map(() => (<>
            <div className="border p-4">
              <p>dao name</p>
            </div>
          </>))}
        </div>
      </div>
      <div className="max-w-md w-full">
        <h2>forum</h2>
        <div className="border h-full">
        </div>
      </div>
    </div>
    <div>
      <h2>finance</h2>
    </div>
    <div>
      <h2>membership</h2>
    </div>
  </>)
}

Page.getLayout = (page: ReactElement) => {
  return (
    <Layout>{page}</Layout>
  )
}

export default Page;
