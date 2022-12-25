import {createSlice} from "@reduxjs/toolkit";

const demoSlice = createSlice({
    name: "demo",
    initialState: {},
    reducers: {
        demo: function (state) {
            console.log("aaa")
            return {"errorDisplay": "none"}
        }
    }
})

export const DemoReducer = demoSlice.reducer
export const DemoActions = demoSlice.actions
