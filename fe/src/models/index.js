import {combineReducers, configureStore} from "@reduxjs/toolkit";
import {LoginReducer} from "./login";
import {DemoReducer} from "./demo";
import {AppReducer} from "./app";

const store = configureStore({
    reducer: combineReducers({
        Login: LoginReducer,
        Demo: DemoReducer,
        App: AppReducer,
    }),
})
export default store
