/*
 * Lenovo 83AL / LJCN18WW: one-shot Darwin PEG1 startup recovery experiment.
 * Add-only: does not rename, delete, or replace any OEM ACPI object.
 * A child _INI runs after the existing PEG1._INI during namespace startup.
 * OEM PON: power GPIO -> bounded clock IPC -> bounded PWGD wait -> reset release.
 * OEM L23D: at most 80 ms + 144 ms, or a no-op when SCB0 != 1.
 * Never call PXP._ON, PEGP._PS0, or the fixed-DGDA NVID field.
 */
DefinitionBlock ("", "SSDT", 2, "83AL", "PEG1ON", 0x00000001)
{
    External (\_SB.PC00.PEG1, DeviceObj)
    External (\_SB.PC00.PC2M, MethodObj)
    External (\_SB.PC00.GPCB, MethodObj)
    External (\_SB.PC00.PEG1.PON, MethodObj)
    External (\_SB.PC00.PEG1.L23D, MethodObj)
    External (\_SB.PC00.PEG1.SCB0, FieldUnitObj)
    External (\_SB.PC00.PEG1.D0ST, FieldUnitObj)

    Scope (\_SB.PC00.PEG1)
    {
        Device (P1ON)
        {
            Name (_HID, "LNV8301")
            Name (_CID, EisaId ("PNP0C02"))
            Name (_UID, One)
            Name (_DDN, "83AL PEG1 startup recovery test")
            Name (DONE, Zero)
            Name (STEP, Zero)
            Name (RSLT, Zero)
            Name (BFLK, Zero)
            Name (AFLK, Zero)
            Name (BFSC, Zero)
            Name (AFSC, Zero)
            Name (CBUS, Zero)
            Name (PCID, 0xFFFFFFFF)

            // Root port is always 00:01.0. Use the firmware's ECAM resolver.
            OperationRegion (BRCF, SystemMemory, \_SB.PC00.PC2M (0x00010000), 0x0100)
            Field (BRCF, DWordAcc, NoLock, Preserve)
            {
                BVID, 32
            }
            // Word/byte accesses avoid writing adjacent PCI status W1C bits.
            Field (BRCF, WordAcc, NoLock, Preserve)
            {
                Offset (0x04), BCMD, 16,
                Offset (0x52), BLNK, 16
            }
            Field (BRCF, ByteAcc, NoLock, Preserve)
            {
                Offset (0x19), BSEC, 8, BSUB, 8
            }

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin")) { Return (0x0F) }
                Return (Zero)
            }

            // Fresh method-local region each call: never use DGDA or bus 1/2 constants.
            Method (RVID, 0, Serialized)
            {
                Local0 = BSEC
                CBUS = Local0
                If (((Local0 == Zero) || (Local0 == 0xFF) || (Local0 > BSUB)))
                {
                    Return (0xFFFFFFFF)
                }
                Local1 = \_SB.PC00.GPCB ()
                If (((Local1 == Zero) || ((Local1 & 0x000FFFFF) != Zero)))
                {
                    Return (0xFFFFFFFF)
                }
                Local1 += (Local0 << 0x14)
                OperationRegion (EPCF, SystemMemory, Local1, 0x04)
                Field (EPCF, DWordAcc, NoLock, Preserve) { EVID, 32 }
                Return (EVID)
            }

            Method (_INI, 0, Serialized)
            {
                If (!_OSI ("Darwin")) { Return (Zero) }
                If (DONE) { Return (Zero) }
                DONE = One
                STEP = One
                // Refuse hardware writes on an unexpected root port.
                If ((BVID != 0xA70D8086))
                {
                    RSLT = 0xE0
                    Return (Zero)
                }
                BFLK = BLNK
                BFSC = \_SB.PC00.PEG1.SCB0
                If ((BFLK & 0x2000))
                {
                    PCID = RVID ()
                    If ((PCID == 0x25AC10DE))
                    {
                        RSLT = 0x02 // Already linked: do not repeat power sequence.
                        FNSH ()
                        Return (Zero)
                    }
                    If (((PCID != 0xFFFFFFFF) && (PCID != Zero)))
                    {
                        RSLT = 0xE4 // Another endpoint: do not power-cycle it.
                        FNSH ()
                        Return (Zero)
                    }
                }

                STEP = 0x02
                \_SB.PC00.PEG1.PON ()
                STEP = 0x03
                // OEM method itself checks SCB0; no fabricated SCB0 value.
                \_SB.PC00.PEG1.L23D ()
                STEP = 0x04
                BCMD |= 0x07
                \_SB.PC00.PEG1.D0ST = Zero
                Sleep (0x0A)

                // One second maximum explicit link polling, irrespective of L23D's result.
                Local0 = Zero
                While (((BLNK & 0x2000) == Zero) && (Local0 < 0x64))
                {
                    Sleep (0x0A)
                    Local0++
                }
                If (((BLNK & 0x2000) == Zero))
                {
                    RSLT = 0xE1 // Link timeout; finish boot instead of waiting forever.
                    FNSH ()
                    Return (Zero)
                }

                STEP = 0x05
                Local0 = Zero
                PCID = RVID ()
                While ((PCID != 0x25AC10DE) && (Local0 < 0x64))
                {
                    Sleep (0x0A)
                    PCID = RVID ()
                    Local0++
                }
                If ((PCID == 0x25AC10DE)) { RSLT = One }
                Else { RSLT = 0xE2 } // Link present, expected endpoint not readable.
                FNSH ()
                Return (Zero)
            }

            Method (FNSH, 0, NotSerialized)
            {
                AFLK = BLNK
                AFSC = \_SB.PC00.PEG1.SCB0
                CBUS = BSEC
                STEP = 0x06
                Notify (\_SB.PC00.PEG1, Zero) // Bus Check, including on bounded failure.
            }

            // Cached experiment results only; querying this never repeats the recovery.
            Method (_DSM, 4, NotSerialized)
            {
                If ((Arg0 == ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de")))
                {
                    If ((Arg2 == Zero)) { Return (Buffer (One) { 0x03 }) }
                    If ((Arg2 == One))
                    {
                        Return (Package ()
                        {
                            "model", "83AL PEG1 startup recovery test",
                            "p1on-version", One,
                            "p1on-done", DONE,
                            "p1on-step", STEP,
                            "p1on-result", RSLT,
                            "p1on-link-before", BFLK,
                            "p1on-link-after", AFLK,
                            "p1on-scb0-before", BFSC,
                            "p1on-scb0-after", AFSC,
                            "p1on-bus", CBUS,
                            "p1on-pci-id", PCID
                        })
                    }
                }
                Return (Buffer (One) { 0x00 })
            }
        }
    }
}
