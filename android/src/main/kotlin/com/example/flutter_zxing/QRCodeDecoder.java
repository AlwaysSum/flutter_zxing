package com.example.flutter_zxing;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.ChecksumException;
import com.google.zxing.DecodeHintType;
import com.google.zxing.FormatException;
import com.google.zxing.NotFoundException;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeReader;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

public class QRCodeDecoder {
    private static byte[] yuvs;
    public static int MAX_PICTURE_PIXEL = 256;
    public static final Map<DecodeHintType, Object> HINTS = new EnumMap<>(DecodeHintType.class);

    public static void config() {
        HINTS.clear();
        List<BarcodeFormat> allFormats = new ArrayList<>();
        allFormats.add(BarcodeFormat.AZTEC);
        allFormats.add(BarcodeFormat.CODABAR);
        allFormats.add(BarcodeFormat.CODE_39);
        allFormats.add(BarcodeFormat.CODE_93);
        allFormats.add(BarcodeFormat.CODE_128);
        allFormats.add(BarcodeFormat.DATA_MATRIX);
        allFormats.add(BarcodeFormat.EAN_8);
        allFormats.add(BarcodeFormat.EAN_13);
        allFormats.add(BarcodeFormat.ITF);
        allFormats.add(BarcodeFormat.MAXICODE);
        allFormats.add(BarcodeFormat.PDF_417);
        allFormats.add(BarcodeFormat.QR_CODE);
        allFormats.add(BarcodeFormat.RSS_14);
        allFormats.add(BarcodeFormat.RSS_EXPANDED);
        allFormats.add(BarcodeFormat.UPC_A);
        allFormats.add(BarcodeFormat.UPC_E);
        allFormats.add(BarcodeFormat.UPC_EAN_EXTENSION);
        HINTS.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
        HINTS.put(DecodeHintType.POSSIBLE_FORMATS, allFormats);
        HINTS.put(DecodeHintType.CHARACTER_SET, "utf-8");
//        HINTS.put(DecodeHintType.PURE_BARCODE, Boolean.TRUE);
    }

    public static String syncDecodeQRCode(String path) {
        config();
        Bitmap bitmap = pathToBitMap(path, MAX_PICTURE_PIXEL, MAX_PICTURE_PIXEL);
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        byte[] mData = getYUV420sp(bitmap.getWidth(), bitmap.getHeight(), bitmap);

        Result result = decodeImage(mData, width, height);
        if (result != null) return result.getText();
        return null;
    }

    public static String decodeImageQRCodeByte(byte[] data, int width, int height) {
        Result result = decodeImage(data, width, height);
        if (result != null) return result.getText();
        return null;
    }
    
    private static Result decodeImage(byte[] data, int width, int height) {
        // 处理
        Result result = null;
        try {
            PlanarYUVLuminanceSource source =
                    new PlanarYUVLuminanceSource(data, width, height, 0, 0, width, height, false);
            BinaryBitmap bitmap1 = new BinaryBitmap(new GlobalHistogramBinarizer(source));
            QRCodeReader reader2 = new QRCodeReader();
            result = reader2.decode(bitmap1, HINTS);
        } catch (FormatException | ChecksumException ignored) {
        } catch (NotFoundException e) {
            PlanarYUVLuminanceSource source =
                    new PlanarYUVLuminanceSource(data, width, height, 0, 0, width, height, false);
            BinaryBitmap bitmap1 = new BinaryBitmap(new HybridBinarizer(source));
            QRCodeReader reader2 = new QRCodeReader();
            try {
                result = reader2.decode(bitmap1, HINTS);
            } catch (NotFoundException | ChecksumException | FormatException ignored) {
            }
        }
        return result;
    }

    private static Bitmap pathToBitMap(String imgPath, int reqWidth, int reqHeight) {
        final BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(imgPath, options);

        // Calculate inSampleSize
        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight);

        // Decode bitmap with inSampleSize set
        options.inJustDecodeBounds = false;
        return BitmapFactory.decodeFile(imgPath, options);
    }

    private static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        // Raw height and width of image
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {

            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while ((halfHeight / inSampleSize) > reqHeight && (halfWidth / inSampleSize) > reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    private static byte[] getYUV420sp(int inputWidth, int inputHeight, Bitmap scaled) {
        int[] argb = new int[inputWidth * inputHeight];

        scaled.getPixels(argb, 0, inputWidth, 0, 0, inputWidth, inputHeight);

        int requiredWidth = inputWidth % 2 == 0 ? inputWidth : inputWidth + 1;
        int requiredHeight = inputHeight % 2 == 0 ? inputHeight : inputHeight + 1;

        int byteLength = requiredWidth * requiredHeight * 3 / 2;
        if (yuvs == null || yuvs.length < byteLength) {
            yuvs = new byte[byteLength];
        } else {
            Arrays.fill(yuvs, (byte) 0);
        }

        encodeYUV420SP(yuvs, argb, inputWidth, inputHeight);

        scaled.recycle();

        return yuvs;
    }

    private static void encodeYUV420SP(byte[] yuv420sp, int[] argb, int width, int height) {
        // 帧图片的像素大小
        final int frameSize = width * height;
        // ---YUV数据---
        int Y, U, V;
        // Y的index从0开始
        int yIndex = 0;
        // UV的index从frameSize开始
        int uvIndex = frameSize;

        // ---颜色数据---
        // int a, R, G, B;
        int R, G, B;
        //
        int argbIndex = 0;
        //

        // ---循环所有像素点，RGB转YUV---
        for (int j = 0; j < height; j++) {
            for (int i = 0; i < width; i++) {

                // a is not used obviously
                // a = (argb[argbIndex] & 0xff000000) >> 24;
                R = (argb[argbIndex] & 0xff0000) >> 16;
                G = (argb[argbIndex] & 0xff00) >> 8;
                B = (argb[argbIndex] & 0xff);
                //
                argbIndex++;

                // well known RGB to YUV algorithm
                Y = ((66 * R + 129 * G + 25 * B + 128) >> 8) + 16;
                U = ((-38 * R - 74 * G + 112 * B + 128) >> 8) + 128;
                V = ((112 * R - 94 * G - 18 * B + 128) >> 8) + 128;

                //
                Y = Math.max(0, Math.min(Y, 255));
                U = Math.max(0, Math.min(U, 255));
                V = Math.max(0, Math.min(V, 255));

                // NV21 has a plane of Y and interleaved planes of VU each sampled by a factor of 2
                // meaning for every 4 Y pixels there are 1 V and 1 U. Note the sampling is every other
                // pixel AND every other scanline.
                // ---Y---
                yuv420sp[yIndex++] = (byte) Y;
                // ---UV---
                if ((j % 2 == 0) && (i % 2 == 0)) {
                    //
                    yuv420sp[uvIndex++] = (byte) V;
                    //
                    yuv420sp[uvIndex++] = (byte) U;
                }
            }
        }
    }


    public static String decodeQRCode(Context context, String path) {
        BitmapFactory.Options sizeOptions = new BitmapFactory.Options();
        sizeOptions.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, sizeOptions);
        BitmapFactory.Options decodeOptions = new BitmapFactory.Options();
        if (sizeOptions.outWidth * sizeOptions.outHeight * 3 > 10 * 1024 * 1024) {
            Log.i("scan", String.format("bitmap too large %d x %d", sizeOptions.outWidth, sizeOptions.outHeight));
            decodeOptions.inSampleSize = 2;
        }
//        Bitmap bitmap = BitmapFactory.decodeFile(path, decodeOptions);
//        HmsScanAnalyzerOptions options = new HmsScanAnalyzerOptions.Creator().setPhotoMode(true).create();
//        HmsScan[] hmsScans = ScanUtil.decodeWithBitmap(context, bitmap, options);
//
//        if (hmsScans != null && hmsScans.length > 0) {
//            return hmsScans[0].getOriginalValue();
//        }
        return syncDecodeQRCode(path);
    }
}
