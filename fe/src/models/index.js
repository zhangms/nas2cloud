import {combineReducers, configureStore} from "@reduxjs/toolkit";
import {LoginReducer} from "./login";
import {DemoReducer} from "./demo";
import {AppReducer} from "./app";
import {FileReducer} from "./file";

const store = configureStore({
    reducer: combineReducers({
        Login: LoginReducer,
        Demo: DemoReducer,
        App: AppReducer,
        File: FileReducer,
    }),
})
export default store
