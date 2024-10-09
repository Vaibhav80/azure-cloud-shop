import {
  app,
  HttpRequest,
  HttpResponseInit,
  InvocationContext,
} from "@azure/functions";
import { products } from "../mocks/productsMock";

export async function HttpGetProductList(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log(`Http function processed request for url "${request.url}"`);

  return { body: JSON.stringify(products) };
}

app.http("HttpGetProductList", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "products/",
  handler: HttpGetProductList,
});
