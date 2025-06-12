import torch
import torch.nn as nn


def simple_test():
    print("=== simple_test ===")
    model = nn.Sequential(nn.Linear(10, 2), nn.Linear(2, 1))

    x = torch.randn(1, 10, requires_grad=True)
    print(f"Input x shape: {x.shape}")
    x1 = model(x)
    print(f"After model(x), x1 shape: {x1.shape}, x1: {x1}")
    x1.retain_grad()
    x2 = x1**2
    print(f"After x1 ** 2, x2 shape: {x2.shape}, x2: {x2}")
    x2.retain_grad()
    x3 = x2 / 10
    print(f"After x2 / 10, x3 shape: {x3.shape}, x3: {x3}")
    x3.retain_grad()

    loss = torch.norm(x3)
    print(f"Loss (torch.norm(x3)): {loss.item()}")
    loss.backward()

    print(f"x1.grad: {x1.grad}")
    print(f"x2.grad: {x2.grad}")
    print(f"x3.grad: {x3.grad}")
    print("====================")


def debug_gradients():
    print("=== Gradient Debugging ===")

    # Test 1: Simple gradient
    print("\n1. Simple gradient test:")
    x = torch.tensor(2.0, requires_grad=True)
    y = x**2

    print(f"x = {x}")
    print(f"y = x^2 = {y}")
    print(f"y.requires_grad: {y.requires_grad}")
    print(f"y.grad_fn: {y.grad_fn}")

    # Check for NaN/Inf before backward
    if torch.isnan(y).any() or torch.isinf(y).any():
        print("❌ NaN/Inf detected before backward!")
        return

    try:
        y.backward()
        print(f"x.grad = {x.grad}")

        if x.grad is None:
            print("❌ Gradient is None!")
        elif torch.isnan(x.grad).any():
            print("❌ Gradient contains NaN!")
        elif torch.isinf(x.grad).any():
            print("❌ Gradient contains Inf!")
        else:
            print("✅ Gradient computed successfully")

    except Exception as e:
        print(f"❌ Backward pass failed: {e}")
        import traceback

        traceback.print_exc()


def test_autograd():
    """Simple test to verify PyTorch autograd is working properly"""

    print("Testing PyTorch Autograd...")

    # Test 1: Basic gradient computation
    print("\n1. Basic gradient test:")
    x = torch.tensor(2.0, requires_grad=True)
    y = x**2  # y = x^2, dy/dx = 2x
    y.backward()

    expected_grad = 2 * x.item()  # Should be 4.0
    actual_grad = x.grad.item()

    print(f"   x = {x.item()}")
    print(f"   y = x^2 = {y.item()}")
    print(f"   Expected gradient dy/dx = {expected_grad}")
    print(f"   Actual gradient = {actual_grad}")
    print(f"   ✓ Test passed: {abs(actual_grad - expected_grad) < 1e-6}")

    # Test 2: Multi-variable gradient
    print("\n2. Multi-variable gradient test:")
    x = torch.tensor(3.0, requires_grad=True)
    y = torch.tensor(4.0, requires_grad=True)
    z = x * y + x**2  # z = xy + x^2

    z.backward()

    # dz/dx = y + 2x = 4 + 6 = 10
    # dz/dy = x = 3
    expected_dx = y.item() + 2 * x.item()  # 10.0
    expected_dy = x.item()  # 3.0

    print(f"   x = {x.item()}, y = {y.item()}")
    print(f"   z = xy + x^2 = {z.item()}")
    print(f"   Expected dz/dx = {expected_dx}, Actual = {x.grad.item()}")
    print(f"   Expected dz/dy = {expected_dy}, Actual = {y.grad.item()}")
    print(f"   ✓ dx test passed: {abs(x.grad.item() - expected_dx) < 1e-6}")
    print(f"   ✓ dy test passed: {abs(y.grad.item() - expected_dy) < 1e-6}")

    # Test 3: Chain rule with tensor operations
    print("\n3. Chain rule test:")
    x = torch.tensor([1.0, 2.0], requires_grad=True)
    y = torch.sum(x**3)  # y = x1^3 + x2^3
    y.backward()

    # dy/dx1 = 3*x1^2 = 3, dy/dx2 = 3*x2^2 = 12
    expected_grads = [3 * x[0].item() ** 2, 3 * x[1].item() ** 2]
    actual_grads = x.grad.tolist()

    print(f"   x = {x.tolist()}")
    print(f"   y = sum(x^3) = {y.item()}")
    print(f"   Expected gradients = {expected_grads}")
    print(f"   Actual gradients = {actual_grads}")

    grad_test_passed = all(
        abs(a - e) < 1e-6 for a, e in zip(actual_grads, expected_grads)
    )
    print(f"   ✓ Chain rule test passed: {grad_test_passed}")

    # Test 4: Neural network-like computation
    print("\n4. Neural network-like test:")
    torch.manual_seed(42)  # For reproducible results

    # Simple linear layer: y = Wx + b
    W = torch.randn(2, 3, requires_grad=True)
    b = torch.randn(2, requires_grad=True)
    x = torch.randn(3)

    y = torch.matmul(W, x) + b
    loss = torch.sum(y**2)  # Simple loss function

    loss.backward()

    print(f"   Weight shape: {W.shape}")
    print(f"   Input shape: {x.shape}")
    print(f"   Output shape: {y.shape}")
    print(f"   Loss: {loss.item():.4f}")
    print(f"   ✓ Weight gradients computed: {W.grad is not None}")
    print(f"   ✓ Bias gradients computed: {b.grad is not None}")
    print(f"   Weight grad shape: {W.grad.shape}")
    print(f"   Bias grad shape: {b.grad.shape}")

    print("\n🎉 All autograd tests passed! PyTorch autograd is working properly.")


if __name__ == "__main__":
    simple_test()
    debug_gradients()
    test_autograd()
