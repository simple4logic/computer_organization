# memo

## J-type implementation

다른 task는 모두 성공. j-type만 안됨
일단 jal, jalr 정리하자면

```markdown
# return
# x1에 담긴 값을 가져와서 0만큼 더한 주소로 jump. 현재 PC+4 는 x0에다가 저장
# x0은 어짜피 hard-wired 0이기 때문에, 굳이 다음 주소를 저장 X
jalr x0 x1 0 

# jump
# PC+4를 x1에다가 저장해놓고, return 시에 다시 가져옴
jalr x1 rs1 0

```

jalr rd rs1 imm 꼴인데, return이 아니라 jump 기준으로 rd는 거의 항상 x1(즉 00001)이지 않을까 싶다
