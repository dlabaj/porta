// @flow

import React from 'react'

import { createReactWrapper } from 'utilities/createReactWrapper'

type Props = {
  newProductPath: string,
  productsPath: string,
  products: Array<{
    id: number,
    link: string,
    links: Array<{
      name: string,
      path: string
    }>,
    name: string,
    type: string,
    updated_at: string
  }>
}

const ProductsWidget = (props: Props) => {
  console.log(props)

  return (
    <div>Products</div>
  )
}

const ProductsWidgetWrapper = (props: Props, containerId: string) => createReactWrapper(<ProductsWidget {...props} />, containerId)

export { ProductsWidgetWrapper }
