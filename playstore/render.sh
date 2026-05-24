#!/usr/bin/env bash
# Render Play Store assets via headless Brave, then crop the 81-row white strip
# Brave headless adds at the bottom (hidden URL bar). Output goes to output/.
set -euo pipefail
cd "$(dirname "$0")"

BRAVE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
EXTRA=120  # render with extra height; will crop to exact target after.

render() {
  local url="$1" out="$2" target_w="$3" target_h="$4"
  local render_h=$((target_h + EXTRA))
  "$BRAVE" --headless --disable-gpu --no-sandbox --hide-scrollbars \
    --force-device-scale-factor=1 \
    --window-size="${target_w},${render_h}" \
    --screenshot="output/_raw_${out}" "$url" 2>&1 | tail -1
  # Top-left anchored crop via Python (sips -c is centered, no good)
  python3 - <<PY
import struct, zlib
src='output/_raw_${out}'; dst='output/${out}'
tw, th = ${target_w}, ${target_h}
with open(src,'rb') as f: data=f.read()
pos=8
while pos<len(data):
    L=struct.unpack('>I',data[pos:pos+4])[0]
    if data[pos+4:pos+8]==b'IHDR':
        w,h,bit,col=struct.unpack('>IIBB',data[pos+8:pos+18]); break
    pos+=12+L
bpp={0:1,2:3,3:1,4:2,6:4}[col]; s=w*bpp
pos,idat=8,b''
while pos<len(data):
    L=struct.unpack('>I',data[pos:pos+4])[0]
    if data[pos+4:pos+8]==b'IDAT': idat+=data[pos+8:pos+8+L]
    pos+=12+L
raw=zlib.decompress(idat); rows=[]; prev=bytes(s); rp=0
for y in range(h):
    ft=raw[rp]; rp+=1
    line=bytearray(raw[rp:rp+s]); rp+=s
    if ft==1:
        for i in range(bpp,s): line[i]=(line[i]+line[i-bpp])&0xff
    elif ft==2:
        for i in range(s): line[i]=(line[i]+prev[i])&0xff
    elif ft==3:
        for i in range(s):
            a=line[i-bpp] if i>=bpp else 0
            line[i]=(line[i]+(a+prev[i])//2)&0xff
    elif ft==4:
        for i in range(s):
            a=line[i-bpp] if i>=bpp else 0; b=prev[i]; c=prev[i-bpp] if i>=bpp else 0
            p=a+b-c; pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
            pr=a if pa<=pb and pa<=pc else (b if pb<=pc else c)
            line[i]=(line[i]+pr)&0xff
    prev=bytes(line); rows.append(prev)
# Top-left crop
cropped=bytearray()
for y in range(th):
    cropped += b'\x00' + rows[y][:tw*bpp]
# Re-encode PNG
def chunk(t, d):
    crc=zlib.crc32(t+d)
    return struct.pack('>I',len(d))+t+d+struct.pack('>I',crc)
sig=b'\x89PNG\r\n\x1a\n'
ihdr=struct.pack('>IIBBBBB', tw, th, 8, col, 0, 0, 0)
idat_compressed=zlib.compress(bytes(cropped),9)
with open(dst,'wb') as f:
    f.write(sig+chunk(b'IHDR',ihdr)+chunk(b'IDAT',idat_compressed)+chunk(b'IEND',b''))
PY
  rm -f "output/_raw_${out}"
}

BASE="file://$(pwd)/template.html"

render "${BASE}?img=raw/dashboard.png&h1=Track%20%3Cspan%20class%3D%22hl%22%3Eevery%20rupee%3C%2Fspan%3E%20automatically.&h2=Tally%20reads%20your%20bank%20SMS%20and%20logs%20transactions%20for%20you%20%E2%80%94%20no%20manual%20entry." \
  01_dashboard.png 1080 1920

render "${BASE}?img=raw/spending.png&h1=See%20where%20your%20%3Cspan%20class%3D%22hl%22%3Emoney%20goes%3C%2Fspan%3E&h2=Beautiful%20monthly%20breakdowns%20with%20limits%2C%20over-budget%20alerts%2C%20and%20more." \
  02_spending.png 1080 1920

render "${BASE}?img=raw/inbox.png&h1=Bank%20SMS%20%E2%86%92%20%3Cspan%20class%3D%22hl%22%3ELogged%3C%2Fspan%3E&h2=Tally%20reads%20your%20bank%20SMS%20and%20queues%20each%20payment%20for%20one-tap%20approval." \
  03_inbox.png 1080 1920

render "${BASE}?img=raw/budget.png&h1=Set%20limits.%20%3Cspan%20class%3D%22hl%22%3EStay%20on%20track.%3C%2Fspan%3E&h2=Plan%20every%20category.%20Daily%20limits%2C%20real-time%20tracking%2C%20zero%20spreadsheets." \
  04_budget.png 1080 1920

render "${BASE}?img=raw/onboarding.png&h1=Set%20up%20in%20%3Cspan%20class%3D%22hl%22%3E60%20seconds%3C%2Fspan%3E&h2=Pick%20your%20country%2C%20set%20your%20budget%2C%20done.%20Tally%20handles%20the%20rest." \
  05_onboarding.png 1080 1920

render "file://$(pwd)/feature_graphic.html" feature_graphic.png 1024 500
render "file://$(pwd)/app_icon.html"        app_icon_512.png   512  512

echo "Done."
ls -la output/
