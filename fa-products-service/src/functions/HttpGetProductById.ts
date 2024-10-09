import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from "@azure/functions";
import { products } from "../mocks/productsMock";

export async function HttpGetProductById(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);
  const productId = request.params.productId;

  const product = products.find((item) => item.id === productId);

  if (product) {
    return { body: JSON.stringify(product) };
  }

  return {
    status: 404,
    body: JSON.stringify({ message: `Product not found` }),
  };
}

app.http("HttpGetProductById", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "products/{productId}",
  handler: HttpGetProductById,
});
