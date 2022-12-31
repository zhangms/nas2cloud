import {createSlice} from "@reduxjs/toolkit";

const fileSlice = createSlice({
    name: "fileSlice",
    initialState: {
        initLoading: true,
        moreLoading: false,
        data: []
    },
    reducers: {
        initLoading: function (state, action) {
            return {...state, initLoading: true}
        },

        moreLoading: function (state, action) {
            return {...state, moreLoading: true}
        },

        onLoaded: function (state, action) {
            return {
                initLoading: false,
                moreLoading: false,
                data: action.payload
            }
        }
    }
})

export const FileReducer = fileSlice.reducer
export const FileActions = fileSlice.actions