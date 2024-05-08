for ($i = 1; $i -le 200; $i++) {
    Invoke-WebRequest -Uri "http://13.64.64.181:80/productpage" -OutFile $null
}