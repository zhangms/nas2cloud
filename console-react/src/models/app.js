import {createSlice} from "@reduxjs/toolkit";
import API from "../requests/api";


const appSlice = createSlice({
    name: "app",
    initialState: {
        isLogged: API.isLogged()
    },
    reducers: {
        updateLoginState: function (state, action) {
            return {
                isLogged: API.isLogged()
            }
        }
    }
})

export const AppReducer = appSlice.reducer
export const AppActions = appSlice.actions
