import { createBrowserRouter } from "react-router";
import { SearchScreen } from "./components/SearchScreen";
import { ResultsScreen } from "./components/ResultsScreen";
import { DetailScreen } from "./components/DetailScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: SearchScreen,
  },
  {
    path: "/results",
    Component: ResultsScreen,
  },
  {
    path: "/detail/:hotelId",
    Component: DetailScreen,
  },
]);
