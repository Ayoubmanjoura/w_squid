Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DisplaySettings {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public ushort dmSpecVersion;
        public ushort dmDriverVersion;
        public ushort dmSize;
        public ushort dmDriverExtra;
        public uint dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public uint dmDisplayOrientation;
        public uint dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public ushort dmLogPixels;
        public uint dmBitsPerPel;
        public uint dmPelsWidth;
        public uint dmPelsHeight;
        public uint dmDisplayFlags;
        public uint dmDisplayFrequency;
        public uint dmICMMethod;
        public uint dmICMIntent;
        public uint dmMediaType;
        public uint dmDitherType;
        public uint dmReserved1;
        public uint dmReserved2;
        public uint dmPanningWidth;
        public uint dmPanningHeight;
    }

    [DllImport("user32.dll")]
    public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    public static bool SetRefreshRate(uint refreshRate) {
        DEVMODE vDevMode = new DEVMODE();
        vDevMode.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODE));
        const int ENUM_CURRENT_SETTINGS = -1;
        const int CDS_UPDATEREGISTRY = 0x00000001;
        const int DISP_CHANGE_SUCCESSFUL = 0;

        if (EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref vDevMode) == 0)
            return false;

        vDevMode.dmDisplayFrequency = refreshRate;
        vDevMode.dmFields = 0x400000; // DM_DISPLAYFREQUENCY

        int ret = ChangeDisplaySettings(ref vDevMode, CDS_UPDATEREGISTRY);
        return (ret == DISP_CHANGE_SUCCESSFUL);
    }
}
"@

if ([DisplaySettings]::SetRefreshRate(144)) {
    Write-Output "Refresh rate set to 144Hz successfully."
} else {
    Write-Output "Failed to set refresh rate. Make sure your monitor supports it and run as admin."
}
